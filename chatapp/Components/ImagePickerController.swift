//
//  ImagePickerController.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import PhotosUI
import SwiftUI

struct ImagePickerController: UIViewControllerRepresentable {
    private let TAG = "ImagePickerController"
    var photoSelectionLimit: Int = 0
    @Binding var images: [UIImage?]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = photoSelectionLimit
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerController

        init(_ parent: ImagePickerController) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
                    
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let error = error {
                            print("Error in ImagePickerController, loadObject \(error)")
                        }
                        
                        guard let currentImage = image as? UIImage else { return }
                        DispatchQueue.main.async {
                            self.parent.images.append(currentImage)
                        }
                    }
                }
            }
        }
    }
}
