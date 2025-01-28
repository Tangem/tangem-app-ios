//
//  Toast.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class Toast<V: View> {
    private let view: V

    private lazy var hostingController: UIHostingController<some View> = {
        // The fixedSize() makes sizeToFit() works correctly
        let controller = UIHostingController(rootView: view.fixedSize())
        controller.view.backgroundColor = .clear

        // Resizes the SUIView to its own size
        controller.view.sizeToFit()

        return controller
    }()

    private var timer: Timer?

    init(view: V) {
        self.view = view
    }

    deinit {
        dismiss(animated: false)
    }

    func present(layout: Layout, type: PresentationTime, animated: Bool = true) {
        guard let keyWindow = UIApplication.shared.windows.last else {
            AppLog.error(error: "UIApplication.keyWindow not found")
            return
        }

        switch type {
        case .always:
            break

        case .temporary(let interval):
            Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                self.dismiss(animated: true) {
                    // Retain a reference to `self` to prevent its deallocation before the dismissal animation completes.
                    withExtendedLifetime(self) {}
                }
            }
        }

        updateFrame(layout: layout, keyWindow: keyWindow)

        // Add animation
        if animated {
            hostingController.view.alpha = 0
            hostingController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }

        keyWindow.addSubview(hostingController.view)

        if animated {
            UIView.animate(withDuration: 0.5, delay: .zero, options: .curveEaseOut) {
                self.hostingController.view.alpha = 1
                self.hostingController.view.transform = .identity
            }
        }
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void = {}) {
        timer?.invalidate()
        timer = nil

        if animated {
            UIView.animate(withDuration: 0.5) {
                self.hostingController.view.alpha = 0
            } completion: { [weak self] _ in
                self?.hostingController.view.removeFromSuperview()
                completion()
            }
        } else {
            hostingController.view.removeFromSuperview()
            completion()
        }
    }

    private func updateFrame(layout: Layout, keyWindow: UIWindow) {
        hostingController.view.center.x = keyWindow.center.x

        switch layout {
        case .top(let padding):
            let hostingViewHeight = hostingController.view.frame.size.height
            let topPadding = padding + hostingViewHeight / 2 + keyWindow.safeAreaInsets.top
            hostingController.view.center.y = topPadding
        case .bottom(let padding):
            let hostingViewHeight = hostingController.view.frame.size.height
            let bottomPadding = padding + hostingViewHeight / 2 + keyWindow.safeAreaInsets.bottom
            hostingController.view.center.y = keyWindow.frame.height - bottomPadding
        }
    }
}

extension Toast {
    enum PresentationTime {
        case always
        case temporary(interval: TimeInterval = 2)
    }

    enum Layout {
        case top(padding: CGFloat = 80)
        case bottom(padding: CGFloat = 80)
    }
}
