//
//  ImagePickerManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/30/26.
//

import SwiftUI
import PhotosUI

// MARK: - Modern Gallery Picker (PHPicker)
struct PhotoPicker: UIViewControllerRepresentable {
	@Binding var selectedImage: UIImage?
	@Environment(\.dismiss) private var dismiss
	
	func makeUIViewController(context: Context) -> PHPickerViewController {
		var config = PHPickerConfiguration()
		config.filter = .images
		config.selectionLimit = 1
		config.selection = .continuous
		config.preferredAssetRepresentationMode = .automatic
		
		let picker = PHPickerViewController(configuration: config)
		picker.delegate = context.coordinator
		return picker
	}
	
	func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, PHPickerViewControllerDelegate { // Now in scope
		let parent: PhotoPicker
		init(_ parent: PhotoPicker) { self.parent = parent }
		
		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			// Dismiss immediately
			picker.dismiss(animated: true)
			
			guard let provider = results.first?.itemProvider,
					provider.canLoadObject(ofClass: UIImage.self) else { return }
			
			provider.loadObject(ofClass: UIImage.self) { image, _ in
				DispatchQueue.main.async {
					self.parent.selectedImage = image as? UIImage
				}
			}
		}
	}
}

// MARK: - Native Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
	@Binding var selectedImage: UIImage?
	@Environment(\.dismiss) private var dismiss
	
	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = .camera
		picker.allowsEditing = true
		picker.cameraCaptureMode = .photo
		picker.showsCameraControls = true
		picker.delegate = context.coordinator
		return picker
	}
	
	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		let parent: CameraPicker
		init(_ parent: CameraPicker) { self.parent = parent }
		
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			parent.selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
			parent.dismiss()
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
	}
}

// MARK: - Image Picker Manager Modifier
struct ImagePickerManager: ViewModifier {
	@Binding var selectedImage: UIImage?
	@Binding var isPresented: Bool
	
	@State private var showCamera = false
	@State private var showGallery = false
	
	func body(content: Content) -> some View {
		content
			.confirmationDialog("Select Option", isPresented: $isPresented, titleVisibility: .visible) {
				
				// Logic for image NOT selected
				Button("CAMERA") { showCamera = true }
				
				Button("PHOTO GALLERY") { showGallery = true }
				
				if selectedImage != nil {
					Button("REMOVE", role: .destructive) { selectedImage = nil }
				}
				
				Button("Cancel", role: .cancel) { }
				
			}
			.sheet(isPresented: $showCamera) {
				CameraPicker(selectedImage: $selectedImage)
					.ignoresSafeArea()
			}
			.sheet(isPresented: $showGallery) {
				PhotoPicker(selectedImage: $selectedImage)
					.ignoresSafeArea()
			}
	}
}

extension View {
	func imagePickerManager(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>) -> some View {
		self.modifier(ImagePickerManager(selectedImage: selectedImage, isPresented: isPresented))
	}
}

