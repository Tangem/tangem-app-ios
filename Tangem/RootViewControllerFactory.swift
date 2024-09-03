//
//  RootViewControllerFactory.swift
//  Tangem
//
//  Created by m3g0byt3 on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct RootViewControllerFactory {
    func makeRootViewController(for rootView: some View, window: UIWindow) -> UIViewController {
        guard FeatureProvider.isAvailable(.markets) else {
            return UIHostingController(rootView: rootView)
        }

        let adapter = OverlayContentContainerViewControllerAdapter()

        let rootView = rootView
            .environment(\.overlayContentContainer, adapter)
            .environment(\.overlayContentStateObserver, adapter)
            .environment(\.overlayContentStateController, adapter)
            .environment(\.mainWindowSize, window.screen.bounds.size)

        let contentViewController = UIHostingController(rootView: rootView)

        let overlayCollapsedHeight: CGFloat
        let overlayCornerRadius: CGFloat

        if UIDevice.current.hasHomeScreenIndicator {
            overlayCollapsedHeight = Constants.notchDevicesOverlayCollapsedHeight + Constants.overlayCollapsedHeightAdjustment
            overlayCornerRadius = 24.0
        } else {
            overlayCollapsedHeight = Constants.notchlessDevicesOverlayCollapsedHeight + Constants.overlayCollapsedHeightAdjustment
            overlayCornerRadius = 16.0
        }

        let containerViewController = OverlayContentContainerViewController(
            contentViewController: contentViewController,
            contentExpandedVerticalOffset: UIApplication.safeAreaInsets.top,
            overlayCollapsedHeight: overlayCollapsedHeight,
            overlayCornerRadius: overlayCornerRadius
        )

        adapter.set(containerViewController)

        return containerViewController
    }
}

// MARK: - Constants

private extension RootViewControllerFactory {
    enum Constants {
        static let notchDevicesOverlayCollapsedHeight = 100.0
        static let notchlessDevicesOverlayCollapsedHeight = 86.0
        static let overlayCollapsedHeightAdjustment = 2.0
    }
}
