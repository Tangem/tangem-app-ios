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
        if #available(iOS 16.0, *) {
            modifier(ScreenCaptureProtectionIOS16AndAboveViewModifier())
        } else {
            modifier(ScreenCaptureProtectionIOS15AndBelowViewModifier())
        }
    }
}

// MARK: - Private implementation iOS 15

@available(iOS, deprecated: 16.0, message: "Not used on iOS 16+, can be safely removed")
private struct ScreenCaptureProtectionIOS15AndBelowViewModifier: ViewModifier {
    @State private var contentSizeChange: CGSize?

    func body(content: Content) -> some View {
        ScreenCaptureProtectionContainerView(
            content: { content },
            onContentSizeChange: { contentSizeChange = $0 }
        )
        .frame(width: contentSizeChange?.width, height: contentSizeChange?.height)
    }
}

// MARK: - Private implementation iOS 16+

@available(iOS 16.0, *)
private struct ScreenCaptureProtectionIOS16AndAboveViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        ScreenCaptureProtectionContainerView { content }
    }
}

@available(iOS 16.0, *)
private final class PreferredContentSizeForwardingUIHostingController<T>: UIHostingController<T> where T: View {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentSize = view.bounds.size
        if contentSize != preferredContentSize {
            preferredContentSize = view.bounds.size
        }
    }
}

// MARK: - Private implementation shared

private struct ScreenCaptureProtectionContainerView<Content>: UIViewControllerRepresentable where Content: View {
    typealias UIViewControllerType = UIViewController
    typealias OnContentSizeChange = (_ size: CGSize) -> Void

    private let content: () -> Content

    @available(iOS, deprecated: 16.0, message: "Not used on iOS 16+, can be safely removed")
    private let onContentSizeChange: OnContentSizeChange?

    @available(iOS, deprecated: 16.0, message: "Use 'init(content:)' instead. Not used on iOS 16+, can be safely removed")
    init(
        content: @escaping () -> Content,
        onContentSizeChange: @escaping OnContentSizeChange
    ) {
        self.content = content
        self.onContentSizeChange = onContentSizeChange
    }

    @available(iOS 16.0, *)
    init(
        content: @escaping () -> Content
    ) {
        self.content = content
        onContentSizeChange = nil
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let containerViewController = ScreenCaptureProtectionContainerViewController()
        let contentViewController: UIViewControllerType

        if #available(iOS 16.0, *) {
            let hostingViewController = PreferredContentSizeForwardingUIHostingController(rootView: content())
            hostingViewController.sizingOptions = .preferredContentSize
            contentViewController = hostingViewController
        } else {
            let rootView = content()
                .readGeometry(\.size) { size in
                    onContentSizeChange?(size)
                }
            contentViewController = UIHostingController(rootView: rootView)
        }

        containerViewController.addChild(contentViewController)

        let containerView = containerViewController.view!
        let contentView = contentViewController.view!

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        contentViewController.didMove(toParent: containerViewController)

        return containerViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

private final class ScreenCaptureProtectionContainerViewController: UIViewController {
    private static var screenCaptureProtectionViewName = [
        "_",
        "UI",
        "Text",
        "Layout",
        "Canvas",
        "View",
    ].joined()

    // This property also maintains a strong reference to the `UITextField` instance
    // (necessary since this instance isn't embedded into the view hierarchy).
    private lazy var uiTextField: UITextField = {
        let uiTextField = UITextField()
        uiTextField.isSecureTextEntry = true
        return uiTextField
    }()

    private var screenCaptureProtectionView: UIView {
        if let view: UIView = uiTextField.firstSubview(where: { NSStringFromClass(type(of: $0)) == Self.screenCaptureProtectionViewName }) {
            return view
        }

        assertionFailure("Unable to find the view of type '\(Self.screenCaptureProtectionViewName)' in the view hierarchy of '\(uiTextField)'")

        return uiTextField.subviews.first ?? UIView()
    }

    override func loadView() {
        view = screenCaptureProtectionView
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if #available(iOS 16.0, *) {
            preferredContentSize = container.preferredContentSize
        }
    }
}

// MARK: - Convenience extensions

private extension UIView {
    func firstSubview<T>(where predicate: (_ subview: UIView) -> Bool) -> T? {
        for subview in subviews {
            if predicate(subview) {
                return subview as? T
            }

            if let firstSubview: T? = subview.firstSubview(where: predicate) {
                return firstSubview
            }
        }

        return nil
    }
}
