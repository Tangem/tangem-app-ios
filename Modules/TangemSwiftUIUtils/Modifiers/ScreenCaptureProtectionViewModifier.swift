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
    func body(content: Content) -> some View {
        ScreenCaptureProtectionContainerView { content }
    }
}

private struct ScreenCaptureProtectionContainerView<Content>: UIViewControllerRepresentable where Content: View {
    typealias UIViewControllerType = UIViewController

    private let content: () -> Content

    init(content: @escaping () -> Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let containerController = ScreenCaptureProtectionContainerViewController()
        let hostingController = UIHostingController(rootView: content())
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

        return containerController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
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
}
