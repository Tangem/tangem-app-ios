//
//  ScreenCaptureProtectionViewModifier.swift
//  TangemSwiftUIUtils
//
//  Created by Andrey Fedorov on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Convenience extensions

public extension View {
    /// Protects the given view from both screenshots and built-in screen recording.
    @ViewBuilder
    func screenCaptureProtection() -> some View {
        modifier(ScreenCaptureProtectionViewModifier())
    }
}

// MARK: - Private implementation

private struct ScreenCaptureProtectionViewModifier: ViewModifier {
    @State private var size: CGSize?

    func body(content: Content) -> some View {
        ScreenCaptureProtectionContainerView(
            content: { content },
            onSizeChange: { size = $0 }
        )
        .frame(width: size?.width, height: size?.height)
        .debugBorder(color: .green)
    }
}

private struct ScreenCaptureProtectionContainerView<Content>: UIViewControllerRepresentable where Content: View {
    typealias UIViewControllerType = UIViewController

    private let content: () -> Content
    private let onSizeChange: (_ size: CGSize) -> Void

    init(
        content: @escaping () -> Content,
        onSizeChange: @escaping (_ size: CGSize) -> Void
    ) {
        self.content = content
        self.onSizeChange = onSizeChange
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let containerController = ScreenCaptureProtectionContainerViewController()
        let hostingController = _UIHostingController(
            rootView: content()
                .readGeometry(
                    \.size,
                    onChange: { size in
                        onSizeChange(size)
                        _ = print("\(#function) called at \(CACurrentMediaTime()) with size: \(size)")
                    }
                )
        )
        containerController.addChild(hostingController)

        let containerView = containerController.view!
        let hostingView = hostingController.view!
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        hostingController.didMove(toParent: containerController)

        hostingView.layer.borderColor = UIColor.red.cgColor
        hostingView.layer.borderWidth = 1.0

        hostingView.backgroundColor = .clear

        containerView.layer.borderColor = UIColor.green.cgColor
        containerView.layer.borderWidth = 2.0

        return containerController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        let _ = print("\(#function) called at \(CACurrentMediaTime()) with \(uiViewController.preferredContentSize)") // TODO: Andrey Fedorov - Add actual implementation
    }
}

private final class ScreenCaptureProtectionContainerViewController: UIViewController {
    // This property also maintains a strong reference to the `UITextField` instance
    // (necessary since this instance isn't embedded into the view hierarchy).
    private lazy var uiTextField: UITextField = {
        let uiTextField = UITextField()
        uiTextField.isSecureTextEntry = true
        return uiTextField
    }()

    private var screenCaptureProtectionView: UIView {
        // TODO: Andrey Fedorov - Find the proper view in the view hierarchy instead
        uiTextField.subviews.first!
    }

    override func loadView() {
        view = screenCaptureProtectionView
    }

//    override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
//        let _ = print("\(#function) called at \(CACurrentMediaTime()) with \(container.preferredContentSize)")
//        super.preferredContentSizeDidChange(forChildContentContainer: container)
//        preferredContentSize = container.preferredContentSize
//    }
}

final class _UIHostingController<T>: UIHostingController<T> where T: View {
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        let _ = print("\(#function) called at \(CACurrentMediaTime()) with \(view.frame) \(view.bounds.size) \(preferredContentSize)")
//        preferredContentSize = view.bounds.size
//    }
}
}
