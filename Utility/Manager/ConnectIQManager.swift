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
/// ### Cold-launch reconnect — how it actually works
///
/// The ConnectIQ SDK only creates `IQDevice` objects during the Garmin Connect
/// URL round-trip (`parseDeviceSelectionResponse(from:)`).  After a cold launch
/// those objects are gone.  The approach here is:
///
/// 1. **Persist** — every time `handleOpenURL` populates the device list we
///    snapshot each device's (UUID, modelName, friendlyName) into
///    `AppSession.pairedDevices` via `PersistedDevice`.
///
/// 2. **Restore** — `restoreSessionIfNeeded()` (called from `PaceApp` via `.task`)
///    reads `AppSession.pairedDevices`, reconstructs lightweight `IQDevice` objects
///    using `IQDevice(uuid:friendlyName:modelName:)`, and calls
///    `register(forDeviceEvents:delegate:)` for each one.
///
/// 3. **Status fires** — the SDK fires `deviceStatusChanged(_:status:)` almost
///    immediately for every re-registered device, populating `deviceStatus` and
///    therefore `connectedDevice` — **no Garmin Connect re-launch required**.
///
/// 4. **BT state restoration** — the `stateRestorationIdentifier` passed to
///    `initialize` hooks into `CBCentralManagerOptionRestoreIdentifierKey`, so iOS
///    can relaunch the app silently when a BT event occurs while suspended.
///
/// ### Checking connection status
/// ```swift
/// ciqManager.isWatchPreviouslyPaired          // ever paired? (cold launch gate)
/// ciqManager.connectedDevice != nil           // live .connected device right now
/// ciqManager.deviceStatus[device.uuid]        // raw status for any device
/// ```
@Observable
class ConnectIQManager: NSObject {
	
	// MARK: - Singleton
	
	static let shared = ConnectIQManager()
	
	// MARK: - Public state  (@Observable auto-publishes changes)
	
	/// All devices returned by the most recent GCM selection callback,
	/// OR reconstructed from persistence on cold launch.
	var devices: [IQDevice] = []
	
	/// Live connection-status for every registered device, keyed by device UUID.
	var deviceStatus: [UUID: IQDeviceStatus] = [:]
	
	/// The first device currently in `.connected` status, or `nil`.
	/// Computed from `deviceStatus` so it updates automatically whenever
	/// the SDK fires `deviceStatusChanged`.
	var connectedDevice: IQDevice? {
		devices.first { deviceStatus[$0.uuid] == .connected }
	}
	
	/// `true` when `AppSession.pairedDevices` has at least one entry.
	/// Use this on cold launch to decide whether to show the watch-required
	/// UI or proceed normally.
	var isWatchPreviouslyPaired: Bool {
		!AppSession.pairedDevices.isEmpty
	}
	
	/// Messages received from the watch app, newest last.
	var receivedMessages: [String] = []
	
	/// `true` while the "install Garmin Connect" UI is visible.
	var showInstallGarminConnect: Bool = false
	
	// MARK: - Private
	
	private let urlScheme   = "connect"
	private let connectIQ   = ConnectIQ.sharedInstance()
	private var targetApp: IQApp?
	
	// MARK: - Lifecycle
	
	private override init() {
		super.init()
		// Pass stateRestorationIdentifier so the SDK registers with
		// CBCentralManagerOptionRestoreIdentifierKey.  iOS can then relaunch
		// the app in the background when a BT event occurs while suspended.
		connectIQ?.initialize(
			withUrlScheme: urlScheme,
			uiOverrideDelegate: self,
			stateRestorationIdentifier: urlScheme
		)
	}
	
	// MARK: - Cold-launch restoration
	
	/// Call once from `PaceApp.body { .task }` after the scene is fully set up.
	///
	/// Reads `AppSession.pairedDevices`, reconstructs an `IQDevice` for every
	/// persisted entry, registers for device events, and re-wires the app target
	/// for the primary paired UUID.  The SDK fires `deviceStatusChanged` almost
	/// immediately, which populates `deviceStatus` / `connectedDevice`.
	func restoreSessionIfNeeded() {
		let persisted = AppSession.pairedDevices
		guard !persisted.isEmpty else {
			print("[CIQ] No persisted devices — skipping cold-launch restore")
			return
		}
		
		print("[CIQ] Restoring \(persisted.count) persisted device(s) on cold launch")
		
		// Reconstruct IQDevice objects from the persisted identity snapshots.
		// IQDevice(uuid:friendlyName:modelName:) is a valid public initialiser
		// that creates a device reference the SDK can use for event registration.
		let reconstructed: [IQDevice] = persisted.compactMap { entry in
			
			guard let uuid = entry.uuid else {
				print("[CIQ] Skipping entry with invalid UUID: \(entry.uuidString)")
				return nil
			}
			
			return IQDevice(id: uuid, modelName: entry.friendlyName, friendlyName: entry.modelName)
		}
		
		guard !reconstructed.isEmpty else {
			print("[CIQ] No valid devices could be reconstructed")
			return
		}
		
		DispatchQueue.main.async {
			// Merge reconstructed devices into the live list without wiping
			// any devices that may have already arrived via a URL callback.
			for device in reconstructed {
				if !self.devices.contains(where: { $0.uuid == device.uuid }) {
					self.devices.append(device)
				}
				// Registering triggers deviceStatusChanged almost immediately,
				// which sets deviceStatus[uuid] to the real live status.
				self.connectIQ?.register(forDeviceEvents: device, delegate: self)
			}
			
			// Re-wire app-messaging target for the primary paired UUID.
			if let primaryUUID = AppSession.pairedWatchUUID,
			   let target = reconstructed.first(where: { $0.uuid.uuidString == primaryUUID }) {
				self.connectToApp(uuidString: target.uuid.uuidString, device: target)
			}
		}
	}
	
	// MARK: - Device discovery
	
	/// Opens Garmin Connect Mobile for device selection.
	/// After the user confirms, GCM deep-links back and `handleOpenURL` fires.
	func findDevices() {
		connectIQ?.showDeviceSelection()
	}
	
	/// Handles the deep-link callback from Garmin Connect.
	/// Call from `onOpenURL` in `PaceApp`.
	func handleOpenURL(_ url: URL) {
		guard url.scheme == urlScheme else { return }
		
		guard let parsedDevices = connectIQ?.parseDeviceSelectionResponse(from: url) as? [IQDevice],
			  !parsedDevices.isEmpty else {
			print("[CIQ] handleOpenURL: no devices in response")
			return
		}
		
		DispatchQueue.main.async {
			// Replace the in-memory list (SDK docs: always use the latest authorised set)
			self.devices     = parsedDevices
			self.deviceStatus = [:]     // reset stale statuses
			
			for device in parsedDevices {
				self.connectIQ?.register(forDeviceEvents: device, delegate: self)
			}
			
			// ── Persist for cold-launch restore ──────────────────────────────
			let snapshot = parsedDevices.map {
				PersistedDevice(
					uuidString:   $0.uuid.uuidString,
					modelName:    $0.modelName   ?? "",
					friendlyName: $0.friendlyName ?? ""
				)
			}
			AppSession.pairedDevices   = snapshot
			AppSession.pairedWatchUUID = parsedDevices.first?.uuid.uuidString
			
			print("[CIQ] handleOpenURL: saved \(snapshot.count) device(s)")
			snapshot.forEach { print("[CIQ]  • \($0.modelName) (\($0.uuidString))") }
		}
	}
	
	// MARK: - App communication
	
	/// Registers the watch app for bidirectional messaging.
	/// Also persists the primary UUID so `restoreSessionIfNeeded` knows which
	/// device to re-target on the next cold launch.
	func connectToApp(uuidString: String, device: IQDevice) {
		guard let appUUID   = UUID(uuidString: uuidString) else { return }
		guard let storeUUID = UUID(uuidString: "7243fd4e-7a56-485b-8a27-7eb3e43638fc") else { return }
		
		let app = IQApp(uuid: appUUID, store: storeUUID, device: device)
		targetApp = app
		connectIQ?.register(forAppMessages: app, delegate: self)
		
		AppSession.pairedWatchUUID = device.uuid.uuidString
		print("[CIQ] connectToApp: \(device.modelName ?? device.uuid.uuidString)")
	}
	
	/// Unregisters all listeners, clears the target app, and wipes persistence.
	func disconnectFromApp() {
		if let app = targetApp {
			connectIQ?.unregister(forDeviceEvents: app.device, delegate: self)
			connectIQ?.unregister(forAppMessages: app, delegate: self)
			targetApp = nil
		}
		
		devices.removeAll()
		AppSession.pairedWatchUUID = nil
		AppSession.pairedDevices   = []
		print("[CIQ] disconnectFromApp: persistence cleared")
	}
	
	/// Sends an arbitrary message to the currently targeted watch app.
	func sendMessage(_ message: Any) {
		guard let app = targetApp else {
			print("[CIQ] sendMessage: no targetApp — call connectToApp first")
			return
		}
		connectIQ?.sendMessage(message, to: app, progress: { sent, total in
			print("[CIQ] Progress: \(sent)/\(total)")
		}, completion: { result in
			print("[CIQ] Send result: \(result.rawValue)")
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
	
	/// Single source of truth for all live device connection changes.
	///
	/// Fires:
	/// • During normal use when BT status changes.
	/// • Almost immediately after `register(forDeviceEvents:)` is called —
	///   including the calls inside `restoreSessionIfNeeded()` — so this is
	///   also how we discover connection status after a cold launch.
	///
	/// Mutating `deviceStatus` triggers `@Observable` to re-evaluate
	/// `connectedDevice` and push the change to every observing view.
	func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
		guard let device, let uuid = device.uuid else { return }
		print("[CIQ] deviceStatusChanged — \(device.modelName ?? uuid.uuidString): \(status)")
		
		DispatchQueue.main.async {
			self.deviceStatus[uuid] = status
			
			// Ensure the device is in the live list.
			// This covers the cold-launch path where reconstructed devices were
			// added to `self.devices` before this callback fires.
			if !self.devices.contains(where: { $0.uuid == uuid }) {
				self.devices.append(device)
			}
		}
	}
}

// MARK: - IQAppMessageDelegate

extension ConnectIQManager: IQAppMessageDelegate {
	
	func receivedMessage(_ message: Any!, from app: IQApp!) {
		print("[CIQ] Message from \(app.device?.modelName ?? "unknown"): \(message ?? "")")
		DispatchQueue.main.async {
			if let str = message as? String {
				self.receivedMessages.append(str)
			} else if let dict = message as? [String: Any] {
				self.receivedMessages.append(dict.description)
			}
		}
	}
}
