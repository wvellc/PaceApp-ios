//
//  WatchDevice.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/17/26.
//

import SwiftUI

// MARK: - Watch Device Model

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

