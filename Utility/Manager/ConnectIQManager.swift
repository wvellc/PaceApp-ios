//
//  ConnectIQManager.swift
//  PaceApp
//
//  Created by Wve Developer on 13/04/26.
//

//Imports
import Foundation
import ConnectIQ
import SwiftData

//Garmin watch connect manager
@Observable
class ConnectIQManager: NSObject {
    
    // MARK: - Singleton
    static let shared = ConnectIQManager()
    
    // MARK: - Variables
    var devices: [IQDevice] = [IQDevice(id: UUID(uuidString: "test"), modelName: "Xyz", friendlyName: "Abc")]
    var receivedMessages: [String] = []
    var showInstallGarminConnect: Bool = false
    
    // Replace with the URL scheme you registered in Info.plist
    private let urlScheme = "connect"
    private let connectIQ = ConnectIQ.sharedInstance()
    private var targetApp: IQApp?
    private var modelContext: ModelContext?
    
    // MARK: - Lifecycle of class
    private override init() {
        super.init()
        // 1. Initialize the SDK
        connectIQ?.initialize(withUrlScheme: urlScheme, uiOverrideDelegate: self)
    }

    @MainActor
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Device Management
    func findDevices() {
        // Launches Garmin Connect Mobile to select devices
        connectIQ?.showDeviceSelection()
    }
    
    //Handling open url after device connect from Garmin Connect app
    func handleOpenURL(_ url: URL) {
        guard url.scheme == urlScheme else { return }
        
        // Parse devices from the URL callback
        if let parsedDevices = connectIQ?.parseDeviceSelectionResponse(from: url) as? [IQDevice] {
            DispatchQueue.main.async {
                self.devices = parsedDevices
                
                // Register to listen to connection events for each device
                for device in parsedDevices {
                    self.connectIQ?.register(forDeviceEvents: device, delegate: self)
                }
            }
        }
    }
    
    // MARK: - App Communication
    //Register events listener
    func connectToApp(uuidString: String, device: IQDevice) {
        guard let appUUID = UUID(uuidString: uuidString) else { return }
        guard let storeUUID = UUID(uuidString: "7243fd4e-7a56-485b-8a27-7eb3e43638fc") else { return }
        //bec1b23d90564b958370b9ded9266942
        let app = IQApp(uuid: appUUID, store: storeUUID, device: device)
        self.targetApp = app
        
        // Register to receive messages from the watch app
        connectIQ?.register(forAppMessages: app, delegate: self)
    }
    
    //Unregister events listener
    func disconnectFromApp() {
        if let device = targetApp?.device {
            connectIQ?.unregister(forDeviceEvents: device, delegate: self)
            targetApp = nil
        }
    }
    
    //Send data to watch
    func sendMessage(_ message: Any) {
        guard let app = targetApp else { return }
        
        connectIQ?.sendMessage(message, to: app, progress: { sent, total in
            print("Progress: \(sent)/\(total)")
        }, completion: { result in
            print("Message send finished with result: \(result.rawValue)")
        })
    }
}

// MARK: - Delegates
extension ConnectIQManager: IQUIOverrideDelegate {
    
    //Needs to install garmin connect app
    func needsToInstallConnectMobile() {
        print("Needs To Install Connect Mobile")
        Task {
            // Trigger UI to tell the user they need to install the Garmin App
            self.showInstallGarminConnect = true
            
            ToastManager.shared.present(.warning(String(localized: .pleaseInstallGarminConnectToPairWithYourGarminDevice)))
            
            // Delay for message display
            try? await Task.sleep(for: .milliseconds(1050))
            
            ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
        }
    }
}

extension ConnectIQManager: IQDeviceEventDelegate {
    
    //UI refresh when device status is change
    func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
        print("Device \(device.uuid?.uuidString ?? "") changed status to: \(status.rawValue)")
        // Force a UI refresh if needed
        DispatchQueue.main.async {
//            self.objectWillChange.send()
        }
    }
}

extension ConnectIQManager: IQAppMessageDelegate {
    
    //Recive data from the watch
    func receivedMessage(_ message: Any!, from app: IQApp!) {
        print("Device received message \(message ?? "") from: \(app.device?.modelName ?? "unknown")")
        Task { @MainActor in
            do {
                guard let data = try Self.jsonData(from: message) else {
                    self.receivedMessages.append(String(describing: message ?? ""))
                    return
                }

                guard let modelContext = self.modelContext else {
                    self.receivedMessages.append("Received Garmin payload, but SwiftData is not configured.")
                    return
                }

                let result = try await EventSyncService(modelContext: modelContext).processGarminPayload(data)
                self.receivedMessages.append(
                    "Synced Garmin payload: \(result.created) created, \(result.updated) updated, \(result.skipped) skipped"
                )

                if result.hasErrors {
                    ToastManager.shared.present(.warning("Garmin sync completed with \(result.errors.count) issue(s)."))
                } else {
                    ToastManager.shared.present(.success("Garmin events synced."))
                }
            } catch {
                self.receivedMessages.append("Garmin sync failed: \(error.localizedDescription)")
                ToastManager.shared.present(.error("Garmin sync failed: \(error.localizedDescription)"))
            }
        }
    }

    private static func jsonData(from message: Any?) throws -> Data? {
        if let data = message as? Data {
            return data
        }

        if let string = message as? String {
            return string.data(using: .utf8)
        }

        if let dictionary = message as? [String: Any] {
            return try JSONSerialization.data(withJSONObject: dictionary)
        }

        if let array = message as? [[String: Any]] {
            return try JSONSerialization.data(withJSONObject: array)
        }

        return nil
    }
}
