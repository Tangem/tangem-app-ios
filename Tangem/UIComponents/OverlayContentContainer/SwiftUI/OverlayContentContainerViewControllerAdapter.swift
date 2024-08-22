//
//  OverlayContentContainerViewControllerAdapter.swift
//  Tangem
//
//  Created by m3g0byt3 on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// SwiftUI-compatible adapter for `OverlayContentContainerViewController`.
final class OverlayContentContainerViewControllerAdapter {
    private weak var containerViewController: OverlayContentContainerViewController?

    func set(_ containerViewController: OverlayContentContainerViewController) {
        self.containerViewController = containerViewController
    }
}

// MARK: - OverlayContentContainer protocol conformance

extension OverlayContentContainerViewControllerAdapter: OverlayContentContainer {
    var cornerRadius: CGFloat {
        return containerViewController?.overlayCornerRadius ?? .zero
    }

    func installOverlay(_ overlayView: some View) {
        let overlayViewController = UIHostingController(rootView: overlayView)
        containerViewController?.installOverlay(overlayViewController)
    }

    func removeOverlay() {
        containerViewController?.removeOverlay()
    }
}

// MARK: - OverlayContentStateObserver protocol conformance

extension OverlayContentContainerViewControllerAdapter: OverlayContentStateObserver {
    func addObserver(_ observer: @escaping OverlayContentStateObserver.StateObserver, forToken token: any Hashable) {
        containerViewController?.addObserver(observer, forToken: token)
    }

    func addObserver(_ observer: @escaping OverlayContentStateObserver.ProgressObserver, forToken token: any Hashable) {
        containerViewController?.addObserver(observer, forToken: token)
    }

    func removeObserver(forToken token: any Hashable) {
        containerViewController?.removeObserver(forToken: token)
    }
}

// MARK: - OverlayContentStateController protocol conformance

extension OverlayContentContainerViewControllerAdapter: OverlayContentStateController {
    func collapse() {
        containerViewController?.collapse()
    }

    func expand() {
        containerViewController?.expand()
    }
}
