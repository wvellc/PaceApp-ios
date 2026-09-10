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
    
    /// The last time a sync message was successfully received from the watch.
    /// Seeded from UserDefaults on init so the value survives app restarts.
    var lastWatchSyncDate: Date? = AppSession.lastWatchSyncDate

    /// Formatted sync status string for display in the greeting area.
    /// Returns e.g. "Synced 2 min ago", or a prompt to open the watch app when nil.
    var lastSyncLabel: String {
        guard let date = lastWatchSyncDate else { return "Open Pace App on your Garmin watch to sync" }
        return "Synced \(date.timeAgoDisplay())"
    }

    /// Messages received from the watch app.
    var receivedMessages: [String] = []
    
    /// Events synced from the watch or created locally and sent to the watch.
    var syncedActivities: [ActivityData] = []

    /// Completed events synced from the watch.
    var syncedCompletedActivities: [ActivityData] = []
    
    /// `true` while the Garmin Connect install prompt is visible.
    var showInstallGarminConnect: Bool = false
    
    // MARK: - Private
//	private let logger = Logger(label: "net.paceapp.connectiq")
    private let urlScheme = "connect"
    private let connectIQ = ConnectIQ.sharedInstance()
    private var targetApp: IQApp?
    private var activeEventPayloads: [[String: Any]] = []
    private var completedEventPayloads: [[String: Any]] = []
    private var deletedEventIds: [Int] = []
    // NOTE: syncedEvents, syncedCompletedEvents, deletedEventIds, and watch settings are
    // no longer persisted in UserDefaults — Firestore is the sole persistence layer for all state.
    
    // MARK: - Lifecycle
    
    private override init() {
        super.init()
        // Event arrays start empty — Firestore (with built-in offline cache)
        // seeds them asynchronously in loadPersistedStateFromFirestore().
        // This avoids the synchronous UserDefaults blocking the main thread at launch.
        connectIQ?.initialize(
            withUrlScheme: urlScheme,
            uiOverrideDelegate: self,
            stateRestorationIdentifier: urlScheme
        )
        Task { await loadPersistedStateFromFirestore() }
    }

    // MARK: - Firestore cold-launch state restoration

    // Seeds the in-memory event arrays from Firestore (offline cache = near-instant, no network needed).
    // Called from init() and restoreSessionIfNeeded() — safe to call multiple times.
    @MainActor
    private func loadPersistedStateFromFirestore() async {
        guard let userId = AuthManager.shared.currentUser?.uid else {
            logger.debug("[ConnectIQ] Skipped Firestore event load — no authenticated user")
            return
        }

        do {
            // Single query → client partitions by status. e.g. active: [2], completed: [1], deletedIds: [3]
            let snapshot = try await FirestoreEventRepository.shared.fetchAllEventPayloads(userId: userId)
            activeEventPayloads    = snapshot.activePayloads
            completedEventPayloads = snapshot.completedPayloads
            deletedEventIds        = snapshot.deletedIds
            pruneActivePayloadsAlreadyCompleted()
            rebuildSyncedActivities()
            logger.info("[ConnectIQ] Loaded event state from Firestore", metadata: [
                "active": "\(activeEventPayloads.count)",
                "completed": "\(completedEventPayloads.count)",
                "deleted": "\(deletedEventIds.count)"
            ])
        } catch {
            logger.error("[ConnectIQ] Firestore event load failed", metadata: ["error": "\(error.localizedDescription)"])
        }
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
        
        logger.debug("[ConnectIQ] Polled ConnectIQ device status", metadata: [
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
        
        logger.debug("[ConnectIQ] Updated connected ConnectIQ device", metadata: [
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

        // Re-trigger Firestore event load here in case auth was not ready during init().
        // Safe to call multiple times — loadPersistedStateFromFirestore guards on userId.
        Task { await loadPersistedStateFromFirestore() }

        logger.info("[ConnectIQ] Restoring persisted ConnectIQ devices", metadata: [
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
        logger.info("[ConnectIQ] Presenting ConnectIQ device selection")
        connectIQ?.showDeviceSelection()
    }
    
    /// Handles the GCM deep-link callback. Call from `PaceApp.onOpenURL`.
    func handleOpenURL(_ url: URL) {
        guard url.scheme == urlScheme else { return }
        
        guard let parsedDevices = connectIQ?.parseDeviceSelectionResponse(from: url) as? [IQDevice],
              !parsedDevices.isEmpty else {
            logger.warning("[ConnectIQ] ConnectIQ device selection returned no devices")
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
            
            // Persist for cold-launch restore. Skip any device without a UUID —
            // reading the implicitly-unwrapped `uuid` directly would crash.
            let snapshot = parsedDevices.compactMap { device -> PersistedDevice? in
                guard let uuid = device.uuid else { return nil }
                return PersistedDevice(
                    uuidString:   uuid.uuidString,
                    modelName:    device.modelName   ?? "",
                    friendlyName: device.friendlyName ?? ""
                )
            }
            AppSession.pairedDevices   = snapshot
            AppSession.pairedWatchUUID = parsedDevices.first?.uuid?.uuidString
            self.isWatchPreviouslyPaired = !snapshot.isEmpty
            
            logger.info("[ConnectIQ] Registered ConnectIQ devices from callback", metadata: [
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
        // IQDevice.uuid is an implicitly-unwrapped optional — reading it directly
        // crashes when the SDK hands back a device without one. Unwrap up front.
        guard let deviceUUID = device.uuid else {
            logger.error("[ConnectIQ] Skipped connect — device has no UUID")
            return
        }
        guard let app = getIQApp(device: device) else {
            logger.error("[ConnectIQ] Failed to build ConnectIQ app for device")
            return
        }

        // Unregister previous app if we are switching to a different device
        if let previous = targetApp, previous.device?.uuid != deviceUUID {
            connectIQ?.unregister(forAppMessages: previous, delegate: self)
        }

        targetApp = app
        connectIQ?.register(forAppMessages: app, delegate: self)
        AppSession.pairedWatchUUID = deviceUUID.uuidString
        isWatchPreviouslyPaired = true

        // Reset the sync clock on reconnect — the label prompts the user to open
        // the watch app until a real sync message arrives (lastSyncUpdate).
        clearLastSyncDate()

        logger.info("[ConnectIQ] Registered ConnectIQ app messages", metadata: [
            "device": "\(device.modelName ?? deviceUUID.uuidString)"
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            self?.requestFullSync()
            self?.forceResync()
            // Forward any events that failed to sync while the watch was out of range
            Task { await self?.resyncPendingEvents() }
            // Pull the watch's height/weight to sync gait right after connecting.
            self?.requestSettings()
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
        logger.info("[ConnectIQ] Disconnected ConnectIQ app and cleared local watch state")
    }
    
    /// Sends a message to the currently targeted watch app.
    func sendMessage(_ message: Any) {
        guard let app = targetApp else {
            logger.warning("[ConnectIQ] Skipped ConnectIQ message because no target app is registered")
            return
        }
        
        connectIQ?.sendMessage(message, to: app, progress: nil, completion: { [logger] result in
            logger.debug("[ConnectIQ] ConnectIQ message send completed", metadata: [
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
        logger.info("[ConnectIQ] Upserting synced activity", metadata: ["title": "\(activity.title)"])
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
        logger.info("[ConnectIQ] Upserting synced activity from payload", metadata: ["eventId": "\(eventId(from: payload).map(String.init) ?? "nil")"])
        upsertEventPayload(payload, isCompleted: false, syncStatus: "pending")
    }
    
    func deleteSyncedEvent(id: Int) {
        logger.info("[ConnectIQ] Deleting synced event", metadata: ["eventId": "\(id)"])
        Task { @MainActor in
            // Don't delete on a session that no longer exists — sign out instead of a phantom write.
            guard await AuthManager.shared.verifyAccountStillValid() else { return }
            applyDeletedEventId(id)
            sendMessage([
                "command": "delete_event",
                "source": "phone",
                "id": id
            ])
        }
    }

    func updateEventMetadata(eventId targetEventId: Int, name: String, location: String) {
        logger.info("[ConnectIQ] Updating event metadata", metadata: ["eventId": "\(targetEventId)"])
        var updatedPayload: [String: Any]?
        var isCompleted = false

        if let index = activeEventPayloads.firstIndex(where: { eventId(from: $0) == targetEventId }) {
            var payload = activeEventPayloads[index]
            payload["name"] = name
            payload["location"] = location
            activeEventPayloads[index] = payload
            updatedPayload = payload
            isCompleted = false
        } else if let index = completedEventPayloads.firstIndex(where: { eventId(from: $0) == targetEventId }) {
            var payload = completedEventPayloads[index]
            payload["name"] = name
            payload["location"] = location
            completedEventPayloads[index] = payload
            updatedPayload = payload
            isCompleted = true
        }

        refreshState()

        if let updatedPayload, let userId = AuthManager.shared.currentUser?.uid {
            Task {
                try? await FirestoreEventRepository.shared.upsert(
                    from: updatedPayload,
                    isCompleted: isCompleted,
                    syncStatus: (updatedPayload["syncStatus"] as? String) ?? "synced",
                    source: "phone",
                    userId: userId
                )
            }
        }

        if let updatedPayload {
            sendMessage([
                "command": "create_event",
                "source": "phone",
                "event": updatedPayload
            ])
        }
    }


    // Routes all payload parsing through EventDocumentMapper — single parse path,
    // No duplicate ConnectIQ dict logic.
    private static func activities(from payloads: [[String: Any]]) -> [ActivityData] {
        return payloads.compactMap { payload in
			guard let userId = AuthManager.shared.currentUserID else {
				logger.error("[ConnectIQ] No user ID found for activity payload: \(payload)")
				return nil
			}
            let (doc, segments) = EventDocumentMapper.document(
                from: payload,
                userId: userId,
                isCompleted: false,
                syncStatus: (payload["syncStatus"] as? String) ?? "pending",
                source: (payload["source"] as? String) ?? "watch"
            )
            return EventDocumentMapper.activityData(from: doc, segments: segments)
        }
    }
	
	//Last sync update
	fileprivate func lastSyncUpdate() {
		// persist across restarts
		lastWatchSyncDate = Date()
		AppSession.lastWatchSyncDate = lastWatchSyncDate
	}

	// Clears the sync clock (e.g. on reconnect) so the label prompts to open the watch app.
	private func clearLastSyncDate() {
		lastWatchSyncDate = nil
		AppSession.lastWatchSyncDate = nil
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
            let requestCompleted = eventPayloads(from: dict["completedEvents"])
            let requestActive = eventPayloads(from: dict["activeEvents"])
            reconcileDeletedEventIds(eventIds(from: dict["deletedEventIds"]), liveActive: requestActive, liveCompleted: requestCompleted)
            mergeEventPayloads(requestCompleted, isCompleted: true, syncStatus: "synced")
            mergeEventPayloads(requestActive, isCompleted: false, syncStatus: "synced")
            // Apply remote settings if included
            if let remoteSettings = dict["settings"] as? [String: Any] {
                applyRemoteSettings(remoteSettings)
            }
            refreshState()
				
            // Respond with our full data so the watch gets our events too
            sendFullSync(command: "sync_all", isForceUpdate: isForce)
				
			//Last sync date update
			lastSyncUpdate()

            return true

        // --- SYNC ALL: Watch sends all its data (response to our sync_request) ---
        // We merge but do NOT echo sync_all back — prevents infinite loop.
        case "sync_all":
            if isForce {
                activeEventPayloads.removeAll()
                completedEventPayloads.removeAll()
                deletedEventIds.removeAll()
            }
            let syncCompleted = eventPayloads(from: dict["completedEvents"])
            let syncActive = eventPayloads(from: dict["activeEvents"])
            reconcileDeletedEventIds(eventIds(from: dict["deletedEventIds"]), liveActive: syncActive, liveCompleted: syncCompleted)
            mergeEventPayloads(syncCompleted, isCompleted: true, syncStatus: "synced")
            mergeEventPayloads(syncActive, isCompleted: false, syncStatus: "synced")
            // Apply remote settings if included
            if let remoteSettings = dict["settings"] as? [String: Any] {
                applyRemoteSettings(remoteSettings)
            }
            refreshState()
				
			//Last sync date update
			lastSyncUpdate()

            return true

        // --- DELETE EVENT: Watch deleted a specific event ---
        case "delete_event":
            if let id = eventId(from: dict) {
                applyDeletedEventId(id)
                refreshState()
            }
				
			//Last sync date update
			lastSyncUpdate()

            return true

        // --- CREATE EVENT: Watch created a new active event ---
        case "create_event":
            if let eventPayload = extractEventRecord(from: dict) {
                upsertEventPayload(eventPayload, isCompleted: false, syncStatus: "synced")
            }
				
			//Last sync date update
			lastSyncUpdate()

            return true

        // --- FINISH EVENT: Watch finished an event (active → completed) ---
        case "finish_event":
            if let eventPayload = extractEventRecord(from: dict) {
                upsertEventPayload(eventPayload, isCompleted: true, syncStatus: "synced")
            }
				
			//Last sync date update
			lastSyncUpdate()

            return true

        // --- SYNC SETTINGS: Watch sends updated settings ---
        case "sync_settings":
            if let remoteSettings = dict["settings"] as? [String: Any] {
                applyRemoteSettings(remoteSettings)
            }
				
			//Last sync date update
			lastSyncUpdate()

            return true

        default:
            logger.warning("[ConnectIQ] Received unrecognized sync command", metadata: ["command": "\(command)"])
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
        // No stable id → skip. A clock-based fallback would mint a fresh doc on every
        // resync (duplicates); every real app/watch payload already carries an id.
        guard let id = eventId(from: normalizedPayload) else {
            logger.warning("[ConnectIQ] Skipping event upsert — payload has no id")
            return
        }
        if deletedEventIds.contains(id) {
            return
        }

        normalizedPayload["id"] = id
        normalizedPayload["syncStatus"] = syncStatus
        // Remove legacy syncType if present
        normalizedPayload.removeValue(forKey: "syncType")
        // Canonical distance strings ("14.00") — stored, persisted, and echoed back to the watch in sync_all.
        normalizedPayload = EventDocumentMapper.normalizingWatchDistances(normalizedPayload)

        logger.info("[ConnectIQ] Upserting event", metadata: ["eventId": "\(id)", "completed": "\(isCompleted)"])

        if isCompleted {
            activeEventPayloads.removeAll { eventId(from: $0) == id }
            upsertPayload(normalizedPayload, in: &completedEventPayloads)
        } else {
            guard !completedEventPayloads.contains(where: { eventId(from: $0) == id }) else { return }
            upsertPayload(normalizedPayload, in: &activeEventPayloads)
        }

        refreshState()

        if let userId = AuthManager.shared.currentUser?.uid {
            // App-created payloads tag themselves "phone" explicitly. A payload that
            // reaches here without a source can therefore only have come from the
            // watch, so default to "watch". Either way, the repository preserves the
            // stored source for events that already exist — this only sets it once.
            let source = (normalizedPayload["source"] as? String) ?? "watch"
            Task {
                do {
                    try await FirestoreEventRepository.shared.upsert(
                        from: normalizedPayload,
                        isCompleted: isCompleted,
                        syncStatus: syncStatus,
                        source: source,
                        userId: userId
                    )
                } catch {
                    logger.error("[ConnectIQ] Failed to sync upserted ConnectIQ event to Firestore", metadata: [
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

    // Local-only reconciliation of the watch's bulk tombstone list — a sync replay is
    // not a user action, so it never writes a Firestore delete (live data wins on conflict).
    private func reconcileDeletedEventIds(_ ids: [Int], liveActive: [[String: Any]], liveCompleted: [[String: Any]]) {
        let liveIds = Set(liveActive.compactMap { eventId(from: $0) })
            .union(liveCompleted.compactMap { eventId(from: $0) })
        for id in ids where !liveIds.contains(id) {
            applyDeletedEventLocally(id)
        }
    }

    // Prunes an event from local state and notifies listeners — no Firestore write.
    private func applyDeletedEventLocally(_ id: Int) {
        logger.info("[ConnectIQ] Applying deleted event locally", metadata: ["eventId": "\(id)"])
        if !deletedEventIds.contains(id) {
            deletedEventIds.append(id)
        }

        activeEventPayloads.removeAll { eventId(from: $0) == id }
        completedEventPayloads.removeAll { eventId(from: $0) == id }
        rebuildSyncedActivities()

        // Broadcast so History / Favorites prune the row wherever the delete came from.
        Task { @MainActor in
            EventDeletionCenter.shared.notifyDeleted(eventId: id)
        }
    }

    // A genuine user delete (app action or the watch's delete_event) — prunes local
    // state and also soft-deletes the Firestore doc. Bulk sync tombstones must not reach here.
    private func applyDeletedEventId(_ id: Int) {
        applyDeletedEventLocally(id)

        // Skip ids a previous sync already proved belong to another account.
        guard !AppSession.foreignEventIds.contains(id) else { return }

        if let userId = AuthManager.shared.currentUser?.uid {
            Task {
                do {
                    try await FirestoreEventRepository.shared.softDelete(eventId: id, userId: userId)
                } catch {
                    // Permission denied = the doc is owned by a previous account. Remember
                    // the id so the watch's replay of it isn't retried on every connect.
                    if (error as NSError).code == FirestoreErrorCode.permissionDenied.rawValue {
                        AppSession.foreignEventIds.append(id)
                    }
                    logger.error("[ConnectIQ] Failed to sync deleted ConnectIQ event to Firestore", metadata: [
                        "eventId": "\(id)",
                        "userId": "\(userId)",
                        "error": "\(error.localizedDescription)"
                    ])
                }
            }
        }
    }

    private func pruneActivePayloadsAlreadyCompleted() {
        let completedIds = Set(completedEventPayloads.compactMap { eventId(from: $0) })
        guard !completedIds.isEmpty else { return }

        activeEventPayloads.removeAll { payload in
            guard let id = eventId(from: payload) else { return false }
            return completedIds.contains(id)
        }
    }

    // Cleans up in-memory arrays after any event mutation — prune stale data, then rebuild UI-facing lists.
    private func refreshState() {
        pruneActivePayloadsAlreadyCompleted()
        pruneDeletedEventIds()
        rebuildSyncedActivities()
    }

    // Removes deleted IDs no longer referenced by any event — prevents unbounded growth.
    private func pruneDeletedEventIds() {
        let activeIds    = Set(activeEventPayloads.compactMap { eventId(from: $0) })
        let completedIds = Set(completedEventPayloads.compactMap { eventId(from: $0) })
        deletedEventIds.removeAll { !activeIds.contains($0) && !completedIds.contains($0) }
    }

    private func rebuildSyncedActivities() {
        syncedActivities          = Self.activities(from: activeEventPayloads)
        syncedCompletedActivities = Self.activities(from: completedEventPayloads)
    }

    // MARK: - Pending event resync

    // Sends create_event/finish_event for any in-memory payload still marked syncStatus == "pending".
    // e.g. payload written offline → watch unreachable → retried here on reconnect or app launch.
    func resyncPendingEvents() async {
        let pendingActive = activeEventPayloads.filter { ($0["syncStatus"] as? String) == "pending" }
        let pendingCompleted = completedEventPayloads.filter { ($0["syncStatus"] as? String) == "pending" }

        guard !pendingActive.isEmpty || !pendingCompleted.isEmpty else { return }

        logger.info("[ConnectIQ] Resyncing pending ConnectIQ events", metadata: [
            "pendingActive":    "\(pendingActive.count)",
            "pendingCompleted": "\(pendingCompleted.count)"
        ])

        for payload in pendingActive {
            sendMessage([
                "command": "create_event",
                "source": "phone",
                "event": payload
            ])
        }

        for payload in pendingCompleted {
            sendMessage([
                "command": "finish_event",
                "source": "phone",
                "event": payload
            ])
        }
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

    /// Builds a watch-compatible settings payload from the current user profile in AuthManager.
    /// Keys match the watch's Application.Storage keys exactly.
    /// Source of truth is Firestore (cached in AuthManager.currentUserProfile).
    // Pass gaitOverride to send a freshly computed gait without waiting on the Firestore
    // profile listener (e.g. right after deriving gait from the watch's height).
    func getSettingsPayload(gaitOverride: GaitUserData? = nil) -> [String: Any] {
        guard let profile = AuthManager.shared.userDetails else { return [:] }
        var settings: [String: Any] = [:]
        settings["vibrate_alert"] = profile.intervalVibrate ?? false
        settings["beep_alert"]    = profile.intervalBeep ?? false
        if let gait = gaitOverride ?? profile.gait {
            settings["walking_gait"]         = gait.walkingData.stepLength
            settings["walking_gait_measure"] = Self.watchGaitUnit(gait.walkingData.unit)
            settings["walking_step_length"]  = GaitStrideCalculator.millimeters(stepLength: gait.walkingData.stepLength, unit: gait.walkingData.unit)
            settings["running_gait"]         = gait.runningData.stepLength
            settings["running_gait_measure"] = Self.watchGaitUnit(gait.runningData.unit)
            settings["running_step_length"]  = GaitStrideCalculator.millimeters(stepLength: gait.runningData.stepLength, unit: gait.runningData.unit)
        }
        return settings
    }

    // MARK: - Gait unit / value conversion (watch ⇄ app)

    /// Watch step-length values can arrive as Double, NSNumber or String ("2.5").
    private static func settingDouble(_ value: Any?) -> Double? {
        if let v = value as? Double   { return v }
        if let v = value as? NSNumber { return v.doubleValue }
        if let v = value as? String   { return Double(v) }
        return nil
    }

    /// Normalises the watch unit ("ft"/"m") to the app's full-word form so it
    /// matches the gait segment control. Defaults to "Feet" for anything unknown.
    private static func appGaitUnit(_ raw: Any?) -> String {
        switch (raw as? String)?.lowercased() {
        case "m", "meter", "meters", "metre", "metres": return "Meters"
        default:                                        return "Feet"
        }
    }

    /// Inverse of `appGaitUnit` — the compact form the watch expects on the wire.
    private static func watchGaitUnit(_ unit: String) -> String {
        unit.lowercased().hasPrefix("m") ? "m" : "ft"
    }

    /// Applies settings received from the watch to Firestore (via UserProfileRepository).
    /// Parses each known watch key and writes only the fields that are present in the payload.
    /// Watch → App → Firestore direction.
	func applyRemoteSettings(_ settings: [String: Any]) {
		guard let userId = AuthManager.shared.currentUser?.uid else {
			logger.warning("[ConnectIQ] Skipped applyRemoteSettings — no authenticated user")
			return
		}
		
		// Parse vibrate / beep alert booleans — patch userDetails locally so the
		// Profile toggles refresh instantly, then persist to Firestore.
		let vibrate = settings["vibrate_alert"] as? Bool
		let beep = settings["beep_alert"] as? Bool
		if let vibrate {
			Task { @MainActor in AuthManager.shared.userDetails?.intervalVibrate = vibrate }
			Task {
				try? await UserProfileRepository.shared.updateIntervalVibrate(vibrate, userId: userId)
			}
		}
		if let beep {
			Task { @MainActor in AuthManager.shared.userDetails?.intervalBeep = beep }
			Task {
				try? await UserProfileRepository.shared.updateIntervalBeep(beep, userId: userId)
			}
		}
		
		// Persist body metrics the watch reports: height in cm, weight in grams → kg.
		let watchHeightCm = Self.settingDouble(settings["user_height"])
		let watchWeightKg = Self.settingDouble(settings["user_weight"]).map { $0 / 1000 }
		if watchHeightCm != nil || watchWeightKg != nil {
			Task {
				try? await UserProfileRepository.shared.updateBodyMetrics(heightCm: watchHeightCm, weightKg: watchWeightKg, userId: userId)
			}
		}
		
		// Derive gait from the watch's height (source of truth) — it arrives in a
		// request_settings response. Compute stride via the standard factors, save, and
		// push the computed step lengths back so the watch measures distance correctly.
		if let heightCm = watchHeightCm, heightCm > 0 {
			let gait = GaitStrideCalculator.gait(
				heightCm: heightCm,
				walkingUnit: Self.appGaitUnit(settings["walking_gait_measure"]),
				runningUnit: Self.appGaitUnit(settings["running_gait_measure"])
			)
			// Reply Settings
			var replySettings = getSettingsPayload(gaitOverride: gait)
			if let vibrate { replySettings["vibrate_alert"] = vibrate }
			if let beep { replySettings["beep_alert"] = beep }
			sendMessage([
				"command": "sync_settings",
				"source": "phone",
				"settings": replySettings
			])
			Task {
				try? await UserProfileRepository.shared.updateGait(gait, userId: userId)
			}
		}
		// Otherwise apply the gait the watch reports. Step length arrives as a string
		// (e.g. "2.5") with unit "ft"/"m" — parse leniently, normalise to "Feet"/"Meters".
		else if let wl = Self.settingDouble(settings["walking_gait"]),
				let rl = Self.settingDouble(settings["running_gait"]) {
			let gait = GaitUserData(
				walkingData: GaitData(stepLength: wl, unit: Self.appGaitUnit(settings["walking_gait_measure"])),
				runningData: GaitData(stepLength: rl, unit: Self.appGaitUnit(settings["running_gait_measure"]))
			)
			Task {
				try? await UserProfileRepository.shared.updateGait(gait, userId: userId)
			}
		}
		
		logger.debug("[ConnectIQ] Applied ConnectIQ settings to Firestore", metadata: [
			"settingCount": "\(settings.count)"
		])
	}

    /// Sends all current settings to the watch as a sync_settings command.
    /// Reads from Firestore profile (via getSettingsPayload). Call when a setting changes on phone.
    func sendSettings(gaitOverride: GaitUserData? = nil) {
        sendMessage([
            "command": "sync_settings",
            "source": "phone",
            "settings": getSettingsPayload(gaitOverride: gaitOverride)
        ])
    }

    /// Asks the watch to reply (via sync_settings) with its full settings, including the
    /// user's height — sent once after a watch connects to seed gait from height.
    func requestSettings() {
        sendMessage([
            "command": "request_settings",
            "source": "phone"
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
        logger.warning("[ConnectIQ] Garmin Connect is not installed")
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
        logger.debug("[ConnectIQ] ConnectIQ device status changed", metadata: [
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
		logger.info("\(String(describing: message))")
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

