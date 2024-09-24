//
//  ViewStateHandler.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Convenience extensions

extension View {
    func onWillDisappear(perform: @escaping () -> Void) -> some View {
        modifier(WillDisappearModifier(callback: perform))
    }

    func onDidDisappear(perform: @escaping () -> Void) -> some View {
        modifier(DidDisappearModifier(callback: perform))
    }

    func onWillAppear(perform: @escaping () -> Void) -> some View {
        modifier(WillAppearModifier(callback: perform))
    }

    func onDidAppear(perform: @escaping () -> Void) -> some View {
        modifier(DidAppearModifier(callback: perform))
    }

    /// Consider using this method if you're using two and more life cycle callbacks for the same view.
    /// Using this method is more efficient than using multiple individual lifecycle callbacks.
    func on(
        willAppear: (() -> Void)? = nil,
        didAppear: (() -> Void)? = nil,
        willDisappear: (() -> Void)? = nil,
        didDisappear: (() -> Void)? = nil
    ) -> some View {
        modifier(
            AggregateLifecycleModifier(
                onWillAppear: willAppear,
                onDidAppear: didAppear,
                onWillDisappear: willDisappear,
                onDidDisappear: didDisappear
            )
        )
    }
}

// MARK: - Private implementation

private struct ViewStateHandler: UIViewControllerRepresentable {
    let onWillAppear: (() -> Void)?
    let onDidAppear: (() -> Void)?
    let onWillDisappear: (() -> Void)?
    let onDidDisappear: (() -> Void)?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ViewStateHandler>) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ViewStateHandler>) {
        context.coordinator.onWillAppear = onWillAppear
        context.coordinator.onDidAppear = onDidAppear
        context.coordinator.onWillDisappear = onWillDisappear
        context.coordinator.onDidDisappear = onDidDisappear
    }

    func makeCoordinator() -> ViewStateHandler.Coordinator {
        Coordinator(onWillAppear: onWillAppear, onDidAppear: onDidAppear, onWillDisappear: onWillDisappear, onDidDisappear: onDidDisappear)
    }

    class Coordinator: UIViewController {
        var onWillAppear: (() -> Void)?
        var onDidAppear: (() -> Void)?
        var onWillDisappear: (() -> Void)?
        var onDidDisappear: (() -> Void)?

        init(onWillAppear: (() -> Void)?, onDidAppear: (() -> Void)?, onWillDisappear: (() -> Void)?, onDidDisappear: (() -> Void)?) {
            self.onWillDisappear = onWillDisappear
            self.onWillAppear = onWillAppear
            self.onDidDisappear = onDidDisappear
            self.onDidAppear = onDidAppear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            onWillAppear?()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onDidAppear?()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            onWillDisappear?()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            onDidDisappear?()
        }
    }
}

private struct WillDisappearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: nil,
                onDidAppear: nil,
                onWillDisappear: callback,
                onDidDisappear: nil
            ))
    }
}

private struct DidDisappearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: nil,
                onDidAppear: nil,
                onWillDisappear: nil,
                onDidDisappear: callback
            ))
    }
}

private struct WillAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: callback,
                onDidAppear: nil,
                onWillDisappear: nil,
                onDidDisappear: nil
            ))
    }
}

private struct DidAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: nil,
                onDidAppear: callback,
                onWillDisappear: nil,
                onDidDisappear: nil
            ))
    }
}

private struct AggregateLifecycleModifier: ViewModifier {
    let onWillAppear: (() -> Void)?
    let onDidAppear: (() -> Void)?
    let onWillDisappear: (() -> Void)?
    let onDidDisappear: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: onWillAppear,
                onDidAppear: onDidAppear,
                onWillDisappear: onWillDisappear,
                onDidDisappear: onDidDisappear
            ))
    }
}
