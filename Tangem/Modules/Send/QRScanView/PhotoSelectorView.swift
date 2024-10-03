//
//  PhotoSelectorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import PhotosUI

struct PhotoSelectorView: UIViewControllerRepresentable {
    let viewModel: PhotoSelectorViewModel

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }
}

extension PhotoSelectorView {
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let viewModel: PhotoSelectorViewModel

        init(viewModel: PhotoSelectorViewModel) {
            self.viewModel = viewModel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard
                let itemProvider = results.map(\.itemProvider).first,
                itemProvider.canLoadObject(ofClass: UIImage.self)
            else {
                return
            }

            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let error {
                    AppLog.shared.error(error)
                }

                let image = object as? UIImage
                self?.viewModel.didSelectPhoto(image)
            }
        }
    }
}
