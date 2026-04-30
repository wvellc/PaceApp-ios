//
//  ImagePickerManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/30/26.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
	var sourceType: UIImagePickerController.SourceType = .photoLibrary
	@Binding var selectedFileURL: URL?
	@Environment(\.dismiss) private var dismiss
	
	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.allowsEditing = true
		picker.sourceType = sourceType
		picker.delegate = context.coordinator
		return picker
	}
	
	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		let parent: ImagePicker
		
		init(_ parent: ImagePicker) {
			self.parent = parent
		}
		
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let uiImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
				// Save to temporary directory to get a URL
				if let data = uiImage.jpegData(compressionQuality: 0.8) {
					let filename = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
					try? data.write(to: filename)
					parent.selectedFileURL = filename
				}
			}
			parent.dismiss()
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.dismiss()
		}
	}
}

struct ImagePickerManager: ViewModifier {
    @Binding var selectedFileURL: URL?
    @Binding var isPresented: Bool
    
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Select Option", isPresented: $isPresented, titleVisibility: .hidden) {
                Button("CAMERA") {
                    self.sourceType = .camera
                    self.showImagePicker = true
                }
                Button("PHOTO GALLERY") {
                    self.sourceType = .photoLibrary
                    self.showImagePicker = true
                }
                if selectedFileURL != nil {
                    Button("REMOVE PHOTO", role: .destructive) {
                        selectedFileURL = nil
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                // Ensure you have the ImagePicker struct from the previous response
                ImagePicker(sourceType: sourceType, selectedFileURL: $selectedFileURL)
            }
    }
}

// Convenience extension
extension View {
    func imagePickerManager(isPresented: Binding<Bool>, selectedFileURL: Binding<URL?>) -> some View {
        self.modifier(ImagePickerManager(selectedFileURL: selectedFileURL, isPresented: isPresented))
    }
}
