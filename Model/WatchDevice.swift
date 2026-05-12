//
//  WatchDevice.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/17/26.
//

import Foundation

// MARK: - WatchDevice

/// Represents a discovered Bluetooth watch device.
struct WatchDevice: Identifiable, Hashable, Equatable {
    let id: UUID
    let model: String
    let nickname: String

    init(model: String, nickname: String) {
        self.id = UUID()
        self.model = model
        self.nickname = nickname
    }
}

// MARK: - PersistedDevice

/// A Codable snapshot of an IQDevice's identity fields.
/// Stored in AppSession so the full IQDevice can be reconstructed on cold launch.
/// The ConnectIQ SDK only produces real IQDevice objects from the GCM URL callback,
/// but IQDevice(uuid:friendlyName:modelName:) can be used to recreate them for
/// re-registering device events — the SDK will fill in live status immediately.
struct PersistedDevice: Codable, Equatable {
    let uuidString: String
    let modelName: String
    let friendlyName: String

    var uuid: UUID? { UUID(uuidString: uuidString) }
}
