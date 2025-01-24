//
//  QRScanViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation
import PhotosUI

class QRScanViewModel: ObservableObject, Identifiable {
    @Published var isFlashActive = false
    @Published var actionSheet: ActionSheetBinder?
    @Published var hasCameraAccess = false

    let code: Binding<String>
    let text: String
    let router: QRScanViewRoutable

    init(code: Binding<String>, text: String, router: QRScanViewRoutable) {
        self.code = code
        self.text = text
        self.router = router
    }

    func onAppear() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraAccess = true
        case .denied:
            presentAccessDeniedAlert()
        default:
            requestCameraAccess()
        }
    }

    func toggleFlash() {
        guard
            let camera = AVCaptureDevice.default(for: .video),
            camera.hasTorch
        else {
            return
        }

        do {
            try camera.lockForConfiguration()

            // Do it before the actual changes because it's not immediate
            withAnimation(nil) {
                isFlashActive = !camera.isTorchActive
            }

            camera.torchMode = camera.isTorchActive ? .off : .on
            camera.unlockForConfiguration()
        } catch {
            AppLog.shared.debug("Failed to toggle the flash")
            Analytics.error(error)
        }
    }

    func scanFromGallery() {
        router.openImagePicker()
    }

    func didSelectImage(_ image: UIImage?) {
        guard
            let image,
            let code = scanQRCode(from: image)
        else {
            return
        }

        DispatchQueue.main.async {
            self.code.wrappedValue = code
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.router.dismiss()
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }

            if granted {
                DispatchQueue.main.async {
                    self.hasCameraAccess = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.presentAccessDeniedAlert()
                }
            }
        }
    }

    private func presentAccessDeniedAlert() {
        let sheet = ActionSheet(
            title: Text(Localization.qrScannerCameraDeniedTitle),
            message: Text(Localization.qrScannerCameraDeniedText),
            buttons: [
                .default(Text(Localization.qrScannerCameraDeniedGalleryButton)) { [router] in
                    router.openImagePicker()
                },
                .default(Text(Localization.qrScannerCameraDeniedSettingsButton)) { [router] in
                    router.openSettings()
                },
                .cancel(Text(Localization.commonCancel)) { [router] in
                    router.dismiss()
                },
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    private func scanQRCode(from image: UIImage) -> String? {
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard
            let ciImage = CIImage(image: image),
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: options)
        else {
            return nil
        }

        return detector
            .features(in: ciImage)
            .lazy
            .compactMap { $0 as? CIQRCodeFeature }
            .first?
            .messageString
    }
}
