//
//  OnWillDissapear.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct ViewStateHandler: UIViewControllerRepresentable {
    let onWillAppear: (() -> Void)?
    let onDidAppear: (() -> Void)?
    let onWillDisappear: (() -> Void)?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ViewStateHandler>) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ViewStateHandler>) {
        context.coordinator.onWillAppear = onWillAppear
        context.coordinator.onDidAppear = onDidAppear
        context.coordinator.onWillDisappear = onWillDisappear
    }

    func makeCoordinator() -> ViewStateHandler.Coordinator {
        Coordinator(onWillAppear: onWillAppear, onDidAppear: onDidAppear, onWillDisappear: onWillDisappear)
    }

    class Coordinator: UIViewController {
        var onWillDisappear: (() -> Void)?
        var onWillAppear: (() -> Void)?
        var onDidAppear: (() -> Void)?

        init(onWillAppear: (() -> Void)?, onDidAppear: (() -> Void)?, onWillDisappear: (() -> Void)?) {
            self.onWillDisappear = onWillDisappear
            self.onWillAppear = onWillAppear
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
    }
}

struct WillDisappearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: nil,
                onDidAppear: nil,
                onWillDisappear: callback
            ))
    }
}

struct WillAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: callback,
                onDidAppear: nil,
                onWillDisappear: nil
            ))
    }
}

struct DidAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content
            .background(ViewStateHandler(
                onWillAppear: nil,
                onDidAppear: callback,
                onWillDisappear: nil
            ))
    }
}

extension View {
    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        modifier(WillDisappearModifier(callback: perform))
    }

    func onWillAppear(_ perform: @escaping () -> Void) -> some View {
        modifier(WillAppearModifier(callback: perform))
    }

    func onDidAppear(_ perform: @escaping () -> Void) -> some View {
        modifier(DidAppearModifier(callback: perform))
    }
}
