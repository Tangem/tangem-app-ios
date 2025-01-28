//
//  QRScannerView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SwiftUI

struct QRScanView: View {
    @ObservedObject var viewModel: QRScanViewModel

    @Environment(\.presentationMode) var presentationMode

    private let viewfinderCornerRadius: CGFloat = 2
    private let viewfinderPadding: CGFloat = 55

    var body: some View {
        GeometryReader { geometry in
            cameraView
                .overlay(viewfinder(screenSize: geometry.size))
                .overlay(
                    Color.clear
                        .overlay(viewfinderCrosshair(screenSize: geometry.size))
                        .overlay(textView(screenSize: geometry.size), alignment: .top)
                )
                .overlay(topButtons(), alignment: .top)
        }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .ignoresSafeArea(edges: .bottom)
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var cameraView: some View {
        if viewModel.hasCameraAccess {
            QRScannerView(code: viewModel.code)
        } else {
            Color.black
        }
    }

    private func viewfinder(screenSize: CGSize) -> some View {
        Color.black.opacity(0.6)
            .reverseMask {
                RoundedRectangle(cornerRadius: viewfinderCornerRadius)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: max(100, screenSize.width - viewfinderPadding * 2))
            }
    }

    @ViewBuilder
    private func topButtons() -> some View {
        HStack(spacing: 14) {
            Button(Localization.commonClose) {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(7)
            .style(Fonts.Regular.body, color: .white)

            Spacer()

            Button(action: viewModel.toggleFlash) {
                viewModel.isFlashActive ? Assets.flashDisabled.image : Assets.flash.image
            }
            .padding(7)

            Button(action: viewModel.scanFromGallery) {
                Assets.gallery.image
            }
            .padding(7)
        }
        .padding(.vertical, 21)
        .padding(.horizontal, 9)
    }

    private func viewfinderCrosshair(screenSize: CGSize) -> some View {
        RoundedRectangle(cornerRadius: viewfinderCornerRadius)
            .stroke(.white, lineWidth: 4)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: max(100, screenSize.width - viewfinderPadding * 2))
            .clipShape(CrosshairShape())
    }

    private func textView(screenSize: CGSize) -> some View {
        Text(viewModel.text)
            .style(Fonts.Regular.footnote, color: .white)
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .padding(.horizontal, viewfinderPadding)
            .offset(y: screenSize.height / 2 + screenSize.width / 2 - viewfinderPadding)
    }
}

private struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addPath(cornerPath(rotation: 0, in: rect))
        path.addPath(cornerPath(rotation: 90, in: rect))
        path.addPath(cornerPath(rotation: 180, in: rect))
        path.addPath(cornerPath(rotation: 270, in: rect))
        return path
    }

    private func cornerPath(rotation: Double, in rect: CGRect) -> Path {
        // Top-left corner part of a crosshair
        var path = Path()
        path.move(to: CGPoint(x: -10, y: -10))
        path.addLine(to: CGPoint(x: -10, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 20, y: -10))
        path.closeSubpath()
        return path.rotation(.degrees(rotation)).path(in: rect)
    }
}

private extension View {
    func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask(
            Rectangle()
                .overlay(mask().blendMode(.destinationOut), alignment: alignment)
        )
    }
}

struct QRScanView_Previews_Sheet: PreviewProvider {
    @State static var code: String = ""

    static var previews: some View {
        Text("A")
            .sheet(isPresented: .constant(true)) {
                QRScanView(viewModel: .init(code: $code, text: "Please align your QR code with the square to scan it. Ensure you scan ERC-20 network address.", router: QRScanViewCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })))
                    .background(
                        Image("qr_code_example")
                    )
            }
            .previewDisplayName("Sheet")
    }
}

struct QRScanView_Previews_Inline: PreviewProvider {
    @State static var code: String = ""

    static var previews: some View {
        QRScanView(viewModel: .init(code: $code, text: "Please align your QR code with the square to scan it. Ensure you scan ERC-20 network address.", router: QRScanViewCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })))
            .background(
                Image("qr_code_example")
            )
            .previewDisplayName("Inline")
    }
}

struct QRScannerView: UIViewRepresentable {
    @Binding var code: String

    @Environment(\.presentationMode) var presentationMode

    func makeUIView(context: Context) -> UIQRScannerView {
        let view = UIQRScannerView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIQRScannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(code: $code, presentationMode: presentationMode)
    }

    class Coordinator: NSObject, QRScannerViewDelegate {
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
protocol QRScannerViewDelegate: AnyObject {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ str: String?)
    func qrScanningDidStop()
}

class UIQRScannerView: UIView {
    weak var delegate: QRScannerViewDelegate?

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
        backgroundColor = .black
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

extension UIQRScannerView {
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
        initVideo()
    }

    private func initVideo() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            AppLog.error(error: error)
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

extension UIQRScannerView: AVCaptureMetadataOutputObjectsDelegate {
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
