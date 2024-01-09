//
//  LegacyQRScanner.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SwiftUI

struct LegacyQRScanViewModel: Identifiable {
    let id: UUID = .init()
    let code: Binding<String>
}

struct LegacyQRScanView: View {
    let viewModel: LegacyQRScanViewModel

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(Localization.commonDone) {
                presentationMode.wrappedValue.dismiss()
            }.padding()
            LegacyQRScannerView(code: viewModel.code)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct LegacyQRScanView_Previews: PreviewProvider {
    @State static var code: String = ""

    static var previews: some View {
        LegacyQRScanView(viewModel: .init(code: $code))
    }
}

struct LegacyQRScannerView: UIViewRepresentable {
    @Binding var code: String
    @Environment(\.presentationMode) var presentationMode

    func makeUIView(context: Context) -> LegacyUIQRScannerView {
        let view = LegacyUIQRScannerView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: LegacyUIQRScannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(code: $code, presentationMode: presentationMode)
    }

    class Coordinator: NSObject, LegacyQRScannerViewDelegate {
        @Binding var code: String
        @Binding var presentationMode: PresentationMode

        init(code: Binding<String>, presentationMode: Binding<PresentationMode>) {
            _code = code
            _presentationMode = presentationMode
        }

        func qrScanningDidFail() {
            DispatchQueue.main.async {
                self.presentationMode.dismiss()
            }
        }

        func qrScanningSucceededWithCode(_ str: String?) {
            if let str = str {
                code = str
            }

            DispatchQueue.main.async {
                self.presentationMode.dismiss()
            }
        }

        func qrScanningDidStop() {}
    }
}

/// Delegate callback for the QRScannerView.
protocol LegacyQRScannerViewDelegate: AnyObject {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ str: String?)
    func qrScanningDidStop()
}

class LegacyUIQRScannerView: UIView {
    weak var delegate: LegacyQRScannerViewDelegate?

    /// capture settion which allows us to start and stop scanning.
    var captureSession: AVCaptureSession?
    private var feedbackGenerator: UINotificationFeedbackGenerator?
    // Init methods..
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        doInitialSetup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        doInitialSetup()
    }

    // MARK: overriding the layerClass to return `AVCaptureVideoPreviewLayer`.

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
}

extension LegacyUIQRScannerView {
    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }

    func stopScanning() {
        captureSession?.stopRunning()
        delegate?.qrScanningDidStop()
    }

    /// Does the initial setup for captureSession
    private func doInitialSetup() {
        clipsToBounds = true
        captureSession = AVCaptureSession()
        feedbackGenerator = UINotificationFeedbackGenerator()

        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            initVideo()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                DispatchQueue.main.async {
                    if granted {
                        self?.initVideo()
                    } else {
                        self?.scanningDidFail()
                    }
                }
            })
        }
    }

    private func initVideo() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            AppLog.shared.error(error)
            return
        }

        if captureSession?.canAddInput(videoInput) ?? false {
            captureSession?.addInput(videoInput)
        } else {
            scanningDidFail()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) ?? false {
            captureSession?.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            scanningDidFail()
            return
        }

        layer.session = captureSession
        layer.videoGravity = .resizeAspectFill

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    func scanningDidFail() {
        feedbackGenerator?.notificationOccurred(.error)
        delegate?.qrScanningDidFail()
        captureSession = nil
        feedbackGenerator = nil
    }

    func found(code: String) {
        feedbackGenerator?.notificationOccurred(.success)
        delegate?.qrScanningSucceededWithCode(code)
        feedbackGenerator = nil
    }
}

extension LegacyUIQRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        stopScanning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            // AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
}
