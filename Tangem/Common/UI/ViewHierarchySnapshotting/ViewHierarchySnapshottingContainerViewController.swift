//
//  ViewHierarchySnapshottingContainerViewController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

final class ViewHierarchySnapshottingContainerViewController: UIViewController {
    /// For unknown reasons, in SwiftUI, child view controllers won't inherit `overrideUserInterfaceStyle`
    /// from their parent view controller.
    /// This behavior is still present on iOS 17 and above, despite improvements to the UIKit trait system
    /// in this version of iOS (see https://developer.apple.com/videos/play/wwdc2023/10057/ for more details).
    /// Enable this property to perform manual propagation of `overrideUserInterfaceStyle` to all child view controllers.
    var shouldPropagateOverriddenUserInterfaceStyleToChildren = false

    @discardableResult
    private func performWithOverridingUserInterfaceStyleIfNeeded<T>(
        _ overrideUserInterfaceStyle: UIUserInterfaceStyle?,
        action: () -> T
    ) -> T {
        // Restoring view (and child VCs) state if needed
        defer {
            if overrideUserInterfaceStyle != nil {
                viewIfLoaded?.overrideUserInterfaceStyle = .unspecified

                if shouldPropagateOverriddenUserInterfaceStyleToChildren {
                    propagateOverriddenUserInterfaceStyle(.unspecified, toChildrenOf: self)
                }
            }
        }

        if let overrideUserInterfaceStyle {
            viewIfLoaded?.overrideUserInterfaceStyle = overrideUserInterfaceStyle

            if shouldPropagateOverriddenUserInterfaceStyleToChildren {
                propagateOverriddenUserInterfaceStyle(overrideUserInterfaceStyle, toChildrenOf: self)
            }
        }

        return action()
    }

    private func propagateOverriddenUserInterfaceStyle(
        _ overrideUserInterfaceStyle: UIUserInterfaceStyle,
        toChildrenOf viewController: UIViewController
    ) {
        for child in viewController.children {
            child.overrideUserInterfaceStyle = overrideUserInterfaceStyle
            propagateOverriddenUserInterfaceStyle(overrideUserInterfaceStyle, toChildrenOf: child)
        }
    }

    private func overrideUserInterfaceStyleAssertion(
        _ overrideUserInterfaceStyle: UIUserInterfaceStyle?,
        afterScreenUpdates: Bool
    ) {
        if overrideUserInterfaceStyle != nil, !afterScreenUpdates {
            assertionFailure("`afterScreenUpdates` isn't set, `overrideUserInterfaceStyle` will have no effect")
        }
    }
}

// MARK: - ViewHierarchySnapshotting protocol conformance

extension ViewHierarchySnapshottingContainerViewController: ViewHierarchySnapshotting {
    func makeSnapshotView(afterScreenUpdates: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIView? {
        ensureOnMainQueue()

        guard let snapshotView = viewIfLoaded else {
            return nil
        }

        overrideUserInterfaceStyleAssertion(overrideUserInterfaceStyle, afterScreenUpdates: afterScreenUpdates)

        return performWithOverridingUserInterfaceStyleIfNeeded(overrideUserInterfaceStyle) {
            return snapshotView.snapshotView(afterScreenUpdates: afterScreenUpdates)
        }
    }

    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIImage? {
        ensureOnMainQueue()

        guard let snapshotView = viewIfLoaded else {
            return nil
        }

        overrideUserInterfaceStyleAssertion(overrideUserInterfaceStyle, afterScreenUpdates: afterScreenUpdates)

        return performWithOverridingUserInterfaceStyleIfNeeded(overrideUserInterfaceStyle) {
            let format = UIGraphicsImageRendererFormat.preferred()
            format.opaque = isOpaque

            let bounds = snapshotView.bounds
            let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)

            return renderer.image { _ in
                _ = snapshotView.drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
            }
        }
    }

    func makeSnapshotLayerImage(options: CALayerSnapshotOptions, isOpaque: Bool) -> UIImage? {
        ensureOnMainQueue()

        guard let snapshotView = viewIfLoaded else {
            return nil
        }

        let snapshotLayer: CALayer?
        switch options {
        case .default:
            snapshotLayer = snapshotView.layer
        case .model:
            snapshotLayer = snapshotView.layer.model()
        case .presentation:
            snapshotLayer = snapshotView.layer.presentation()
        }

        guard let snapshotLayer else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = isOpaque

        let bounds = snapshotLayer.bounds
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)

        return renderer.image { context in
            snapshotLayer.render(in: context.cgContext)
        }
    }
}
