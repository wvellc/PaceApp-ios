//
//  ConnectIQManager.swift
//  PaceApp
//
//  Created by Wve Developer on 13/04/26.
//

import Foundation
import ConnectIQ

// MARK: - IQDeviceStatus helpers

extension IQDeviceStatus: @retroactive CustomStringConvertible {
	public var description: String {
		switch self {
			case .invalidDevice:     return "invalidDevice"
			case .bluetoothNotReady: return "bluetoothNotReady"
			case .notConnected:      return "notConnected"
			case .connected:         return "connected"
			case .notFound:          return "notFound"
			@unknown default:        return "unknown(\(rawValue))"
		}
	}
}

// MARK: - ConnectIQManager

/// Singleton that owns all Garmin ConnectIQ SDK interactions.
///
/// ### Why `connectedDevice` is a stored var (not computed)
/// @Observable only tracks stored property accesses. A computed var derived from
/// `deviceStatus` would not wake up views because SwiftUI never saw `deviceStatus`
/// read inside their body — it only saw `connectedDevice`. Making it a stored var
/// that is explicitly written in `deviceStatusChanged` gives every reading view
/// a direct dependency it can wake up on.
///
/// ### Why `getDeviceStatus` is polled after `register(forDeviceEvents:)`
/// `deviceStatusChanged` only fires when the status *changes*. If the watch is
/// already connected when we register (first pairing or cold-launch restore) the
/// delegate never fires. We call `getDeviceStatus(_:)` immediately after registering
/// to read the current status and seed `connectedDevice` without waiting for a change.
@Observable
class ConnectIQManager: NSObject {
	
	// MARK: - Singleton
	
	static let shared = ConnectIQManager()
	
	// MARK: - ConnectIQ App UUID
	// This is the UUID of the PaceApp .iq widget installed on the Garmin watch.
	// It is NOT the device hardware UUID — those are different things.
	private let watchAppUUID = "7243fd4e-7a56-485b-8a27-7eb3e43638fc"
	private let watchStoreUUID = "7243fd4e-7a56-485b-8a27-7eb3e43638fc"
	
	// MARK: - Public stored state
	
	/// All devices from the most recent GCM callback or restored from persistence.
	var devices: [IQDevice] = []
	
	/// Live status map keyed by device UUID. Updated by `deviceStatusChanged`
	/// and by the synchronous `getDeviceStatus` poll in `registerAndPollStatus`.
	var deviceStatus: [UUID: IQDeviceStatus] = [:]
	
	/// The currently connected Garmin watch, or `nil`.
	///
	/// STORED VAR — not computed — so @Observable wakes up every view that
	/// reads it (e.g. HomeScreen's `if ciqManager.connectedDevice == nil`).
	/// Written in `registerAndPollStatus` (immediate seed) and in
	/// `deviceStatusChanged` (live updates thereafter).
	var connectedDevice: IQDevice? = nil
	
	/// `true` when a watch identity has been persisted.
	///
	/// This is a stored var so SwiftUI views that read it, such as HomeScreen's
	/// pair-watch branch, are invalidated when pairing is saved or cleared.
	var isWatchPreviouslyPaired: Bool = !AppSession.pairedDevices.isEmpty
	
	/// Messages received from the watch app.
	var receivedMessages: [String] = []
	
	/// `true` while the Garmin Connect install prompt is visible.
	var showInstallGarminConnect: Bool = false
	
	// MARK: - Private
	
	private let urlScheme = "connect"
	private let connectIQ = ConnectIQ.sharedInstance()
	private var targetApp: IQApp?
	
	// MARK: - Lifecycle
	
	private override init() {
		super.init()
		connectIQ?.initialize(
			withUrlScheme: urlScheme,
			uiOverrideDelegate: self,
			stateRestorationIdentifier: urlScheme
		)
	}
	
	// MARK: - Core: register + immediate status poll
	
	/// Registers a device for events and IMMEDIATELY reads its current status
	/// via `getDeviceStatus(_:)`.
	///
	/// This solves the core problem: `deviceStatusChanged` only fires when status
	/// *changes* — if the watch is already connected when we register (first pairing,
	/// cold launch with watch in range), the delegate is silent and `connectedDevice`
	/// would never be set. The synchronous poll fills that gap.
	private func registerAndPollStatus(for device: IQDevice) {
		// 1. Register — enables the live delegate going forward
		connectIQ?.register(forDeviceEvents: device, delegate: self)
		
		// 2. Immediately read current status (synchronous SDK call)
		guard let uuid = device.uuid else { return }
		let currentStatus = connectIQ?.getDeviceStatus(device) ?? .invalidDevice
		
		print("[CIQ] polled \(device.modelName ?? uuid.uuidString): \(currentStatus)")
		
		// 3. Seed deviceStatus and connectedDevice right now, on the main thread
		DispatchQueue.main.async {
			self.deviceStatus[uuid] = currentStatus
			
			if !self.devices.contains(where: { $0.uuid == uuid }) {
				self.devices.append(device)
			}
			
			self.rederiveConnectedDevice()
		}
	}
	
	/// Re-evaluates `connectedDevice` from the current `deviceStatus` map
	/// and writes it as a stored var so @Observable wakes observing views.
	private func rederiveConnectedDevice() {
		connectedDevice = devices.first { deviceStatus[$0.uuid] == .connected }
		print("[CIQ] connectedDevice → \(connectedDevice?.modelName ?? "nil")")
	}
	
	// MARK: - Cold-launch restoration
	
	/// Call once from `PaceApp.body { .task }` after the scene is ready.
	func restoreSessionIfNeeded() {
		let persisted = AppSession.pairedDevices
		guard !persisted.isEmpty else {
			isWatchPreviouslyPaired = false
			print("[CIQ] No persisted devices — skipping restore")
			return
		}
		isWatchPreviouslyPaired = true
		
		print("[CIQ] Restoring \(persisted.count) device(s) from persistence")
		
		let reconstructed: [IQDevice] = persisted.compactMap { entry in
			guard let uuid = entry.uuid else { return nil }
			return IQDevice(id: uuid, modelName: entry.modelName, friendlyName: entry.friendlyName)
		}
		
		guard !reconstructed.isEmpty else { return }
		
		DispatchQueue.main.async {
			for device in reconstructed {
				if !self.devices.contains(where: { $0.uuid == device.uuid }) {
					self.devices.append(device)
				}
				self.registerAndPollStatus(for: device)
			}
			
			if let primaryUUID = AppSession.pairedWatchUUID,
			   let target = reconstructed.first(where: { $0.uuid.uuidString == primaryUUID }) {
				self.connectToApp(device: target)
			}
		}
	}
	
	// MARK: - Device discovery
	
	func findDevices() {
		connectIQ?.showDeviceSelection()
	}
	
	/// Handles the GCM deep-link callback. Call from `PaceApp.onOpenURL`.
	func handleOpenURL(_ url: URL) {
		guard url.scheme == urlScheme else { return }
		
		guard let parsedDevices = connectIQ?.parseDeviceSelectionResponse(from: url) as? [IQDevice],
			  !parsedDevices.isEmpty else {
			print("[CIQ] handleOpenURL: empty response")
			return
		}
		
		DispatchQueue.main.async {
			// SDK: always replace with the latest authorised set
			self.devices         = parsedDevices
			self.deviceStatus    = [:]
			self.connectedDevice = nil
			
			for device in parsedDevices {
				// registerAndPollStatus reads the CURRENT status immediately —
				// this is what was missing: just register() alone is not enough
				// because the watch may already be connected at this point.
				self.registerAndPollStatus(for: device)
			}
			
			// Persist for cold-launch restore
			let snapshot = parsedDevices.map {
				PersistedDevice(
					uuidString:   $0.uuid.uuidString,
					modelName:    $0.modelName   ?? "",
					friendlyName: $0.friendlyName ?? ""
				)
			}
			AppSession.pairedDevices   = snapshot
			AppSession.pairedWatchUUID = parsedDevices.first?.uuid.uuidString
			self.isWatchPreviouslyPaired = !snapshot.isEmpty
			
			print("[CIQ] handleOpenURL: registered \(snapshot.count) device(s)")
			snapshot.forEach { print("[CIQ]  • \($0.modelName) (\($0.uuidString))") }
		}
	}
	
	// MARK: - App communication
	
	/// Registers the PaceApp ConnectIQ widget on the given device for messaging.
	///
	/// Uses `watchAppUUID` (the .iq widget's UUID) — NOT the device hardware UUID.
	/// Previously `connectToApp(uuidString:device:)` was receiving the device UUID
	/// as `uuidString`, creating an invalid IQApp that the SDK silently dropped.
	func connectToApp(device: IQDevice) {
		guard let appUUID   = UUID(uuidString: watchAppUUID),
			  let storeUUID = UUID(uuidString: watchStoreUUID) else { return }
		
		let app = IQApp(uuid: appUUID, store: storeUUID, device: device)
		targetApp = app
		connectIQ?.register(forAppMessages: app, delegate: self)
		
		AppSession.pairedWatchUUID = device.uuid.uuidString
		isWatchPreviouslyPaired = true
		print("[CIQ] connectToApp: registered app on \(device.modelName ?? device.uuid.uuidString)")
	}
	
	/// Unregisters all listeners, clears all state, and wipes persistence.
	func disconnectFromApp() {
		if let app = targetApp {
			connectIQ?.unregister(forDeviceEvents: app.device, delegate: self)
			connectIQ?.unregister(forAppMessages: app, delegate: self)
			targetApp = nil
		}
		devices.removeAll()
		deviceStatus.removeAll()
		connectedDevice = nil
		AppSession.pairedWatchUUID = nil
		AppSession.pairedDevices   = []
		isWatchPreviouslyPaired = false
		print("[CIQ] disconnectFromApp: all state cleared")
	}
	
	/// Sends a message to the currently targeted watch app.
	func sendMessage(_ message: Any) {
		guard let app = targetApp else {
			print("[CIQ] sendMessage: no targetApp")
			return
		}
		connectIQ?.sendMessage(message, to: app, progress: { sent, total in
			print("[CIQ] send progress: \(sent)/\(total)")
		}, completion: { result in
			print("[CIQ] send result: \(result.rawValue)")
		})
	}
}

// MARK: - IQUIOverrideDelegate

extension ConnectIQManager: IQUIOverrideDelegate {
	
	func needsToInstallConnectMobile() {
		print("[CIQ] Garmin Connect not installed")
		Task {
			self.showInstallGarminConnect = true
			ToastManager.shared.present(
				.warning(String(localized: .pleaseInstallGarminConnectToPairWithYourGarminDevice))
			)
			try? await Task.sleep(for: .milliseconds(1050))
			ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
		}
	}
}

// MARK: - IQDeviceEventDelegate

extension ConnectIQManager: IQDeviceEventDelegate {
	
	/// Fires when device status CHANGES after registration.
	/// Does NOT fire if the device is already connected at registration time —
	/// that case is covered by the `getDeviceStatus` poll in `registerAndPollStatus`.
	func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
		guard let device, let uuid = device.uuid else { return }
		print("[CIQ] deviceStatusChanged — \(device.modelName ?? uuid.uuidString): \(status)")
		
		DispatchQueue.main.async {
			self.deviceStatus[uuid] = status
			
			if !self.devices.contains(where: { $0.uuid == uuid }) {
				self.devices.append(device)
			}
			
			self.rederiveConnectedDevice()
		}
	}
}

// MARK: - IQAppMessageDelegate

extension ConnectIQManager: IQAppMessageDelegate {
	
	func receivedMessage(_ message: Any!, from app: IQApp!) {
		print("[CIQ] message from \(app.device?.modelName ?? "unknown"): \(message ?? "")")
		DispatchQueue.main.async {
			if let str = message as? String {
				self.receivedMessages.append(str)
			} else if let dict = message as? [String: Any] {
				self.receivedMessages.append(dict.description)
			}
		}
	}
}
