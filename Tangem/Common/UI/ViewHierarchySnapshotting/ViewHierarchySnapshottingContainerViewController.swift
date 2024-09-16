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

final class ViewHierarchySnapshottingContainerViewController: UIViewController {}

// MARK: - ViewHierarchySnapshotting protocol conformance

extension ViewHierarchySnapshottingContainerViewController: ViewHierarchySnapshotting {
    func makeSnapshotView(afterScreenUpdates: Bool) -> UIView? {
        ensureOnMainQueue()

        return viewIfLoaded?.snapshotView(afterScreenUpdates: afterScreenUpdates)
    }

    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool) -> UIImage? {
        ensureOnMainQueue()

        guard let snapshotView = viewIfLoaded else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = isOpaque

        let bounds = snapshotView.bounds
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)

        return renderer.image { _ in
            _ = snapshotView.drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
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
