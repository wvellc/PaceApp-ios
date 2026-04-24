//
//  ProfileViewModel+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//
 
import SwiftUI
import PhotosUI
 
// MARK: - Edit Profile State (extends ProfileViewModel)
 
extension ProfileViewModel {
 
    // MARK: - Computed helpers to split full name
 
    var firstName: String {
        get { userName.components(separatedBy: " ").first ?? "" }
        set {
            let last = lastName
            userName = [newValue, last]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
 
    var lastName: String {
        get {
            let parts = userName.components(separatedBy: " ")
            return parts.count > 1 ? parts.dropFirst().joined(separator: " ") : ""
        }
        set {
            let first = firstName
            userName = [first, newValue]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
 
    // MARK: - Update Profile Action
 
    func updateProfile(
        firstName: String,
        lastName: String,
        selectedImage: UIImage?
    ) {
        self.firstName = firstName
        self.lastName = lastName
 
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            // In a real app: upload data to server, then update avatarURL
            // For now we store locally via a placeholder update signal
            _ = data
        }
    }
}
 
