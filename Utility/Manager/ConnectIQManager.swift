//
//  ConnectIQManager.swift
//  PaceApp
//
//  Created by Wve Developer on 13/04/26.
//

import Foundation
import ConnectIQ
import FirebaseAuth
import FirebaseFirestore
import Logging

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
    // watchAppUUID  → the `id` from your watch app's manifest.xml
    //                  Must be in xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx format.
    //                  UUID(uuidString:) returns nil for strings without dashes,
    //                  which silently breaks getIQApp() → targetApp stays nil.
    // watchStoreUUID → the UUID in your Connect IQ Store URL:
    //                  apps.garmin.com/en-US/apps/{THIS-UUID}
    private let watchAppUUID   = "bec1b23d-9056-4b95-8370-b9ded9266942"
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
    
    /// Events synced from the watch or created locally and sent to the watch.
    var syncedActivities: [ActivityData] = []

    /// Completed events synced from the watch.
    var syncedCompletedActivities: [ActivityData] = []
    
    /// `true` while the Garmin Connect install prompt is visible.
    var showInstallGarminConnect: Bool = false
    
    // MARK: - Private
	private let logger = Logger(label: "net.paceapp.connectiq")
    private let urlScheme = "connect"
    private let connectIQ = ConnectIQ.sharedInstance()
    private var targetApp: IQApp?
    private var activeEventPayloads: [[String: Any]] = []
    private var completedEventPayloads: [[String: Any]] = []
    private var deletedEventIds: [Int] = []
    private static let syncedEventsStorageKey = "connectIQ.syncedEvents"
    private static let syncedCompletedEventsStorageKey = "connectIQ.syncedCompletedEvents"
    private static let deletedEventsStorageKey = "connectIQ.deletedEventIds"
    private static let settingsStorageKey = "connectIQ.settings"
    
    // MARK: - Lifecycle
    
    private override init() {
        super.init()
        activeEventPayloads = Self.loadEventPayloads(forKey: Self.syncedEventsStorageKey)
        completedEventPayloads = Self.loadEventPayloads(forKey: Self.syncedCompletedEventsStorageKey)
        deletedEventIds = Self.loadDeletedEventIds()
        pruneActivePayloadsAlreadyCompleted()
        syncedActivities = Self.activities(from: activeEventPayloads)
        syncedCompletedActivities = Self.activities(from: completedEventPayloads)
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
        
        logger.debug("Polled ConnectIQ device status", metadata: [
            "device": "\(device.modelName ?? uuid.uuidString)",
            "status": "\(currentStatus)"
        ])
        
        // 3. Seed deviceStatus and connectedDevice right now, on the main thread
        DispatchQueue.main.async {
            self.deviceStatus[uuid] = currentStatus
            
            if !self.devices.contains(where: { $0.uuid == uuid }) {
                self.devices.append(device)
            }
            
            self.rederiveConnectedDevice()
        }
    }
    
    /// Re-evaluates `connectedDevice` from the current `deviceStatus` map.
    ///
    /// Funnels through `connectToApp(_:)` when a device becomes connected, so
    /// `targetApp` is always set AND `register(forAppMessages:)` is always called.
    /// Previously only `connectedDevice` was written — `targetApp` stayed nil and
    /// message registration was silently skipped.
    /// On disconnect, unregisters message callbacks and clears `targetApp`.
    private func rederiveConnectedDevice() {
        let newConnected = devices.first { deviceStatus[$0.uuid] == .connected }
        
        // No change — nothing to do
        guard newConnected?.uuid != connectedDevice?.uuid else { return }
        
        connectedDevice = newConnected
        
        if let device = newConnected {
            connectToApp(device: device) // sets targetApp + registers for messages
        } else {
            if let app = targetApp {
                connectIQ?.unregister(forAppMessages: app, delegate: self)
            }
            targetApp = nil
        }
        
        logger.debug("Updated connected ConnectIQ device", metadata: [
            "device": "\(connectedDevice?.modelName ?? "nil")",
            "targetAppRegistered": "\(targetApp != nil)"
        ])
    }
    
    // MARK: - Cold-launch restoration
    
    /// Call once from `PaceApp.body { .task }` after the scene is ready.
    func restoreSessionIfNeeded() {
        let persisted = AppSession.pairedDevices
        guard !persisted.isEmpty else {
            isWatchPreviouslyPaired = false
            return
        }
        isWatchPreviouslyPaired = true
        
        logger.info("Restoring persisted ConnectIQ devices", metadata: [
            "deviceCount": "\(persisted.count)"
        ])
        
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
            logger.warning("ConnectIQ device selection returned no devices")
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
            
            self.logger.info("Registered ConnectIQ devices from callback", metadata: [
                "deviceCount": "\(snapshot.count)"
            ])
        }
    }
    
    // MARK: - App communication
    
    /// Builds the IQApp, registers for messages, and sets `targetApp`.
    ///
    /// This is the SINGLE place `targetApp` is assigned. All paths that need a
    /// connected app (rederiveConnectedDevice, restoreSession, handleOpenURL) route
    /// here so `register(forAppMessages:)` is never accidentally skipped.
    func connectToApp(device: IQDevice) {
        guard let app = getIQApp(device: device) else {
            logger.error("Failed to build ConnectIQ app for device")
            return
        }
        
        // Unregister previous app if we are switching to a different device
        if let previous = targetApp, previous.device?.uuid != device.uuid {
            connectIQ?.unregister(forAppMessages: previous, delegate: self)
        }
        
        targetApp = app
        connectIQ?.register(forAppMessages: app, delegate: self)
        AppSession.pairedWatchUUID = device.uuid.uuidString
        isWatchPreviouslyPaired = true
        logger.info("Registered ConnectIQ app messages", metadata: [
            "device": "\(device.modelName ?? device.uuid.uuidString)"
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            self?.requestFullSync()
            self?.forceResync()
        }
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
        logger.info("Disconnected ConnectIQ app and cleared local watch state")
    }
    
    /// Sends a message to the currently targeted watch app.
    func sendMessage(_ message: Any) {
        guard let app = targetApp else {
            logger.warning("Skipped ConnectIQ message because no target app is registered")
            return
        }
        
        connectIQ?.sendMessage(message, to: app, progress: nil, completion: { [logger] result in
            logger.debug("ConnectIQ message send completed", metadata: [
                "result": "\(result.rawValue)"
            ])
        })
    }

    /// Requests a full sync from the watch. Called when the phone connects
    /// or when the user manually triggers a sync.
    func requestFullSync() {
        sendFullSync(command: "sync_request")
    }

    /// Forces a complete resync — clears local cached sync state and
    /// re-sends everything with `is_force_update: true`.
    /// The watch will also resend all its data, ignoring previous sync state.
    func forceResync() {
        sendFullSync(command: "sync_request", isForceUpdate: true)
    }
    
    func upsertSyncedActivity(_ activity: ActivityData) {
        if syncedActivities.contains(where: { existing in
            existing.title == activity.title &&
            existing.date == activity.date &&
            existing.distance == activity.distance &&
            existing.duration == activity.duration &&
            existing.location == activity.location
        }) {
            return
        }
        
        syncedActivities.insert(activity, at: 0)
    }
    
    func upsertSyncedActivity(from payload: [String: Any]) {
        upsertEventPayload(payload, isCompleted: false, syncStatus: "pending")
    }
    
    func deleteSyncedEvent(id: Int) {
        applyDeletedEventId(id)
        sendMessage([
            "command": "delete_event",
            "source": "phone",
            "id": id
        ])
    }

    private static func loadEventPayloads(forKey key: String) -> [[String: Any]] {
        UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
    }

    private static func loadDeletedEventIds() -> [Int] {
        let values = UserDefaults.standard.array(forKey: deletedEventsStorageKey) ?? []
        return values.compactMap { value in
            if let intValue = value as? Int { return intValue }
            if let numberValue = value as? NSNumber { return numberValue.intValue }
            if let stringValue = value as? String { return Int(stringValue) }
            return nil
        }
    }

    private static func activities(from payloads: [[String: Any]]) -> [ActivityData] {
        return payloads.compactMap(ActivityData.init(connectIQPayload:))
    }
    
    // MARK: - Sync Message Handler

    /// Dispatches incoming sync commands from the watch.
    /// Returns true if the message was handled as a sync command.
    ///
    /// Supported commands:
    ///   - `sync_request`: Watch asks phone to send all data (phone responds with sync_all)
    ///   - `sync_all`: Watch sends all its data (phone merges, does NOT echo back)
    ///   - `delete_event`: Watch deleted an event
    ///   - `create_event`: Watch created a new active event
    ///   - `finish_event`: Watch finished an event (move active → completed)
    ///   - `sync_settings`: Watch sends updated settings (alerts, gait)
    private func handleSyncMessage(_ dict: [String: Any]) -> Bool {
        guard let command = dict["command"] as? String else { return false }
        let isForce = dict["is_force_update"] as? Bool ?? false

        switch command {

        // --- SYNC REQUEST: Watch asks phone to send all data ---
        case "sync_request":
            if isForce {
                // Force resync: clear local state to accept everything fresh
                activeEventPayloads.removeAll()
                completedEventPayloads.removeAll()
                deletedEventIds.removeAll()
            }
            applyDeletedEventIds(eventIds(from: dict["deletedEventIds"]))
            mergeEventPayloads(eventPayloads(from: dict["completedEvents"]), isCompleted: true, syncStatus: "synced")
            mergeEventPayloads(eventPayloads(from: dict["activeEvents"]), isCompleted: false, syncStatus: "synced")
            // Apply remote settings if included
            if let remoteSettings = dict["settings"] as? [String: Any] {
                applyRemoteSettings(remoteSettings)
            }
            persistSyncState()
            // Respond with our full data so the watch gets our events too
            sendFullSync(command: "sync_all", isForceUpdate: isForce)
            return true

        // --- SYNC ALL: Watch sends all its data (response to our sync_request) ---
        // We merge but do NOT echo sync_all back — prevents infinite loop.
        case "sync_all":
            if isForce {
                activeEventPayloads.removeAll()
                completedEventPayloads.removeAll()
                deletedEventIds.removeAll()
            }
            applyDeletedEventIds(eventIds(from: dict["deletedEventIds"]))
            mergeEventPayloads(eventPayloads(from: dict["completedEvents"]), isCompleted: true, syncStatus: "synced")
            mergeEventPayloads(eventPayloads(from: dict["activeEvents"]), isCompleted: false, syncStatus: "synced")
            // Apply remote settings if included
            if let remoteSettings = dict["settings"] as? [String: Any] {
                applyRemoteSettings(remoteSettings)
            }
            persistSyncState()
            return true

        // --- DELETE EVENT: Watch deleted a specific event ---
        case "delete_event":
            if let id = eventId(from: dict) {
                applyDeletedEventId(id)
                persistSyncState()
            }
            return true

        // --- CREATE EVENT: Watch created a new active event ---
        case "create_event":
            if let eventPayload = extractEventRecord(from: dict) {
                upsertEventPayload(eventPayload, isCompleted: false, syncStatus: "synced")
            }
            return true

        // --- FINISH EVENT: Watch finished an event (active → completed) ---
        case "finish_event":
            if let eventPayload = extractEventRecord(from: dict) {
                upsertEventPayload(eventPayload, isCompleted: true, syncStatus: "synced")
            }
            return true

        // --- SYNC SETTINGS: Watch sends updated settings ---
        case "sync_settings":
            if let remoteSettings = dict["settings"] as? [String: Any] {
                applyRemoteSettings(remoteSettings)
            }
            return true

        default:
            return false
        }
    }

    /// Sends a full sync payload to the watch.
    /// - Parameters:
    ///   - command: "sync_request" (asking watch to respond) or "sync_all" (sending our data)
    ///   - isForceUpdate: when true, tells the watch to ignore previous sync state
    private func sendFullSync(command: String, isForceUpdate: Bool = false) {
        sendMessage([
            "command": command,
            "source": "phone",
            "is_force_update": isForceUpdate,
            "activeEvents": activeEventPayloads,
            "completedEvents": completedEventPayloads,
            "deletedEventIds": deletedEventIds,
            "settings": getSettingsPayload()
        ])
    }

    private func mergeEventPayloads(_ payloads: [[String: Any]], isCompleted: Bool, syncStatus: String) {
        for payload in payloads {
            upsertEventPayload(payload, isCompleted: isCompleted, syncStatus: syncStatus)
        }
    }

    private func upsertEventPayload(_ payload: [String: Any], isCompleted: Bool, syncStatus: String) {
        var normalizedPayload = payload
        let id = eventId(from: normalizedPayload) ?? Int(Date().timeIntervalSince1970)
        if deletedEventIds.contains(id) {
            return
        }

        normalizedPayload["id"] = id
        normalizedPayload["syncStatus"] = syncStatus
        // Remove legacy syncType if present
        normalizedPayload.removeValue(forKey: "syncType")

        if isCompleted {
            activeEventPayloads.removeAll { eventId(from: $0) == id }
            upsertPayload(normalizedPayload, in: &completedEventPayloads)
        } else {
            guard !completedEventPayloads.contains(where: { eventId(from: $0) == id }) else {
                persistSyncState()
                return
            }
            upsertPayload(normalizedPayload, in: &activeEventPayloads)
        }

        persistSyncState()

        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId).collection("activities").document(String(id))
            let cleaned = cleanPayloadForFirestore(normalizedPayload)
            Task {
                do {
                    try await docRef.setData(cleaned, merge: true)
                } catch {
                    logger.error("Failed to sync upserted ConnectIQ event to Firestore", metadata: [
                        "eventId": "\(id)",
                        "userId": "\(userId)",
                        "error": "\(error.localizedDescription)"
                    ])
                }
            }
        }
    }

    private func upsertPayload(_ payload: [String: Any], in payloads: inout [[String: Any]]) {
        guard let id = eventId(from: payload) else {
            payloads.insert(payload, at: 0)
            return
        }

        if let index = payloads.firstIndex(where: { eventId(from: $0) == id }) {
            payloads[index] = payload
        } else {
            payloads.insert(payload, at: 0)
        }
    }

    private func applyDeletedEventIds(_ ids: [Int]) {
        for id in ids {
            applyDeletedEventId(id)
        }
    }

    private func applyDeletedEventId(_ id: Int) {
        if !deletedEventIds.contains(id) {
            deletedEventIds.append(id)
        }

        activeEventPayloads.removeAll { eventId(from: $0) == id }
        completedEventPayloads.removeAll { eventId(from: $0) == id }
        rebuildSyncedActivities()

        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId).collection("activities").document(String(id))
            Task {
                do {
                    try await docRef.delete()
                } catch {
                    logger.error("Failed to sync deleted ConnectIQ event to Firestore", metadata: [
                        "eventId": "\(id)",
                        "userId": "\(userId)",
                        "error": "\(error.localizedDescription)"
                    ])
                }
            }
        }
    }

    private func cleanPayloadForFirestore(_ payload: [String: Any]) -> [String: Any] {
        var cleaned: [String: Any] = [:]
        for (key, value) in payload {
            if let nsArray = value as? NSArray {
                cleaned[key] = nsArray.compactMap { element -> Any? in
                    if let dict = element as? [String: Any] {
                        return cleanPayloadForFirestore(dict)
                    }
                    return element
                }
            } else if let nestedDict = value as? [String: Any] {
                cleaned[key] = cleanPayloadForFirestore(nestedDict)
            } else {
                cleaned[key] = value
            }
        }
        return cleaned
    }

    private func pruneActivePayloadsAlreadyCompleted() {
        let completedIds = Set(completedEventPayloads.compactMap { eventId(from: $0) })
        guard !completedIds.isEmpty else { return }

        activeEventPayloads.removeAll { payload in
            guard let id = eventId(from: payload) else { return false }
            return completedIds.contains(id)
        }
    }

    /// Persists all sync state to UserDefaults.
    /// Also prunes stale data before saving.
    private func persistSyncState() {
        pruneActivePayloadsAlreadyCompleted()
        pruneDeletedEventIds()
        rebuildSyncedActivities()
        UserDefaults.standard.set(activeEventPayloads, forKey: Self.syncedEventsStorageKey)
        UserDefaults.standard.set(completedEventPayloads, forKey: Self.syncedCompletedEventsStorageKey)
        UserDefaults.standard.set(deletedEventIds, forKey: Self.deletedEventsStorageKey)
    }

    /// Removes deleted event IDs that no longer exist in any event list.
    /// Prevents the deletedEventIds array from growing unbounded.
    private func pruneDeletedEventIds() {
        let activeIds = Set(activeEventPayloads.compactMap { eventId(from: $0) })
        let completedIds = Set(completedEventPayloads.compactMap { eventId(from: $0) })
        deletedEventIds.removeAll { id in
            !activeIds.contains(id) && !completedIds.contains(id)
        }
    }

    private func rebuildSyncedActivities() {
        syncedActivities = Self.activities(from: activeEventPayloads)
        syncedCompletedActivities = Self.activities(from: completedEventPayloads)
    }

    private func eventPayloads(from value: Any?) -> [[String: Any]] {
        if let payloads = value as? [[String: Any]] {
            return payloads
        }
        if let array = value as? NSArray {
            return array.compactMap { $0 as? [String: Any] }
        }
        return []
    }

    private func eventIds(from value: Any?) -> [Int] {
        if let ids = value as? [Int] {
            return ids
        }
        if let array = value as? [Any] {
            return array.compactMap { value in
                if let intValue = value as? Int { return intValue }
                if let numberValue = value as? NSNumber { return numberValue.intValue }
                if let stringValue = value as? String { return Int(stringValue) }
                return nil
            }
        }
        return []
    }

    private func eventId(from payload: [String: Any]) -> Int? {
        if let id = payload["id"] as? Int {
            return id
        }
        if let id = payload["id"] as? NSNumber {
            return id.intValue
        }
        if let id = payload["id"] as? String {
            return Int(id)
        }
        return nil
    }
    
    // MARK: - Settings Sync
    
    /// Settings keys synced between watch and phone.
    /// These match the watch's Application.Storage keys exactly.
    private static let settingsKeys: [String] = [
        "vibrate_alert",
        "beep_alert",
        "walking_gait",
        "walking_gait_measure",
        "running_gait",
        "running_gait_measure"
    ]

    /// Returns a dictionary of all synced settings from UserDefaults.
    func getSettingsPayload() -> [String: Any] {
        var settings: [String: Any] = [:]
        let stored = UserDefaults.standard.dictionary(forKey: Self.settingsStorageKey) ?? [:]
        for key in Self.settingsKeys {
            settings[key] = stored[key]
        }
        return settings
    }

    /// Applies settings received from the watch to local UserDefaults.
    /// Only updates keys that are present and non-nil in the remote payload.
    func applyRemoteSettings(_ settings: [String: Any]) {
        var stored = UserDefaults.standard.dictionary(forKey: Self.settingsStorageKey) ?? [:]
        for key in Self.settingsKeys {
            if let value = settings[key] {
                stored[key] = value
            }
        }
        UserDefaults.standard.set(stored, forKey: Self.settingsStorageKey)
        logger.debug("Applied ConnectIQ settings", metadata: [
            "settingCount": "\(stored.count)"
        ])
    }

    /// Sends all current settings to the watch as a sync_settings command.
    /// Call this when the user changes any setting on the phone.
    func sendSettings() {
        sendMessage([
            "command": "sync_settings",
            "source": "phone",
            "settings": getSettingsPayload()
        ])
    }
    
    func getIQApp(device: IQDevice) -> IQApp? {
        guard let appUUID   = UUID(uuidString: watchAppUUID),
              let storeUUID = UUID(uuidString: watchStoreUUID) else { return nil }
        return IQApp(uuid: appUUID, store: storeUUID, device: device)
    }
}

// MARK: - IQUIOverrideDelegate

extension ConnectIQManager: IQUIOverrideDelegate {
    
    func needsToInstallConnectMobile() {
        logger.warning("Garmin Connect is not installed")
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
        logger.debug("ConnectIQ device status changed", metadata: [
            "device": "\(device.modelName ?? uuid.uuidString)",
            "status": "\(status)"
        ])
        
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
    
    /// Handles all incoming messages from the watch app.
    /// First tries to dispatch as a sync command; if not recognized,
    /// falls back to treating the message as a raw event record (legacy support).
    func receivedMessage(_ message: Any!, from app: IQApp!) {
        DispatchQueue.main.async {
            if let str = message as? String {
                self.receivedMessages.append(str)
            } else if let dict = message as? [String: Any] {
                self.receivedMessages.append(dict.description)

                // Try to handle as a sync command first
                if self.handleSyncMessage(dict) {
                    return
                }

                // Legacy fallback: treat unrecognized dict as a raw event record
                if let eventPayload = self.extractEventRecord(from: dict) {
                    self.upsertEventPayload(eventPayload, isCompleted: false, syncStatus: "synced")
                }
            }
        }
    }
}

// MARK: - Payload Extraction Helper

extension ConnectIQManager {

    /// Extracts an event record from various message formats.
    /// Mirrors the watch's `getEventRecordFromPayload()` function.
    ///
    /// Supports:
    ///   - `{ "event": { ... } }` — event nested under "event" key
    ///   - `{ "payload": { ... } }` — event nested under "payload" key
    ///   - `{ "name": ..., "date": ... }` — event fields directly in dict
    func extractEventRecord(from dict: [String: Any]) -> [String: Any]? {
        if let event = dict["event"] as? [String: Any] { return event }
        if let payload = dict["payload"] as? [String: Any] { return payload }
        if dict["name"] != nil || dict["date"] != nil || dict["distance"] != nil { return dict }
        return nil
    }
}
