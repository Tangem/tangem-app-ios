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

        // TODO: Andrey Fedorov - Adjust all numeric values here for different devices and safe area (IOS-7664)
        let containerViewController = OverlayContentContainerViewController(
            contentViewController: contentViewController,
            contentExpandedVerticalOffset: UIApplication.safeAreaInsets.top,
            overlayCollapsedHeight: 102.0,
            overlayCornerRadius: UIDevice.current.hasHomeScreenIndicator ? 24.0 : 16.0
        )

        adapter.set(containerViewController)

        return containerViewController
    }
}
