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
    private func performWithOverridingUserInterfaceStyleIfNeeded<T>(
        _ overrideUserInterfaceStyle: UIUserInterfaceStyle?,
        onView targetView: UIView,
        action: () -> T
    ) -> T {
        // Restoring view state if needed
        defer {
            if overrideUserInterfaceStyle != nil {
                targetView.overrideUserInterfaceStyle = .unspecified
            }
        }

        if let overrideUserInterfaceStyle {
            targetView.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        }

        return action()
    }

    private func overrideUserInterfaceStyleAssertion(_ style: UIUserInterfaceStyle?, afterScreenUpdates: Bool) {
        if style != nil, !afterScreenUpdates {
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

        return performWithOverridingUserInterfaceStyleIfNeeded(overrideUserInterfaceStyle, onView: snapshotView) {
            return snapshotView.snapshotView(afterScreenUpdates: afterScreenUpdates)
        }
    }

    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIImage? {
        ensureOnMainQueue()

        guard let snapshotView = viewIfLoaded else {
            return nil
        }

        overrideUserInterfaceStyleAssertion(overrideUserInterfaceStyle, afterScreenUpdates: afterScreenUpdates)

        return performWithOverridingUserInterfaceStyleIfNeeded(overrideUserInterfaceStyle, onView: snapshotView) {
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
