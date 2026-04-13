//
//  ConnectIQManager.swift
//  PaceApp
//
//  Created by Wve Developer on 13/04/26.
//

import Foundation
import ConnectIQ

@Observable
class ConnectIQManager: NSObject {
    
    static let shared = ConnectIQManager()
    
     var devices: [IQDevice] = []
     var receivedMessages: [String] = []
     var showInstallGarminConnect: Bool = false
    
    // Replace with the URL scheme you registered in Info.plist
    private let urlScheme = "connect"
    private let connectIQ = ConnectIQ.sharedInstance()
    private var targetApp: IQApp?
    
    private override init() {
        super.init()
        // 1. Initialize the SDK
        connectIQ?.initialize(withUrlScheme: urlScheme, uiOverrideDelegate: self)
    }
    
    // MARK: - Device Management
    func findDevices() {
        // Launches Garmin Connect Mobile to select devices
        connectIQ?.showDeviceSelection()
    }
    
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
    func connectToApp(uuidString: String, device: IQDevice) {
        guard let appUUID = UUID(uuidString: uuidString) else { return }
        guard let storeUUID = UUID(uuidString: "7243fd4e-7a56-485b-8a27-7eb3e43638fc") else { return }

        let app = IQApp(uuid: appUUID, store: storeUUID, device: device)
        self.targetApp = app
        
        // Register to receive messages from the watch app
        connectIQ?.register(forAppMessages: app, delegate: self)
    }
    
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
    func needsToInstallConnectMobile() {
        DispatchQueue.main.async {
            // Trigger UI to tell the user they need to install the Garmin App
            self.showInstallGarminConnect = true
        }
    }
}

extension ConnectIQManager: IQDeviceEventDelegate {
    func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
        print("Device \(device.uuid?.uuidString ?? "") changed status to: \(status.rawValue)")
        // Force a UI refresh if needed
        DispatchQueue.main.async {
//            self.objectWillChange.send()
        }
    }
}

extension ConnectIQManager: IQAppMessageDelegate {
    func receivedMessage(_ message: Any!, from app: IQApp!) {
        DispatchQueue.main.async {
            if let msgString = message as? String {
                self.receivedMessages.append(msgString)
            } else if let dict = message as? [String: Any] {
                self.receivedMessages.append(dict.description)
            }
        }
    }
}
