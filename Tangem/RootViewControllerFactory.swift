//
//  RootViewControllerFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TangemUIUtils

struct RootViewControllerFactory {
    func makeRootViewController(for rootView: some View, window: UIWindow) -> UIViewController {
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
            overlayCornerRadius = Constants.notchDevicesOverlayCornerRadius
        } else {
            overlayCollapsedHeight = Constants.notchlessDevicesOverlayCollapsedHeight + Constants.overlayCollapsedHeightAdjustment
            overlayCornerRadius = Constants.notchlessDevicesOverlayCornerRadius
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

extension RootViewControllerFactory {
    enum Constants {
        /// Based on Figma mockups.
        fileprivate static let notchDevicesOverlayCollapsedHeight = 100.0
        /// Based on Figma mockups.
        fileprivate static let notchlessDevicesOverlayCollapsedHeight = 86.0
        /// The height of `SwiftUI.TextField` used in the `CustomSearchBar` UI components differs from the mockups by this small margin.
        fileprivate static let overlayCollapsedHeightAdjustment = 2.0
        static let notchDevicesOverlayCornerRadius = 24.0
        static let notchlessDevicesOverlayCornerRadius = 16.0
    }
}
