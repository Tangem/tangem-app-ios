//
//  ViewHierarchySnapshottingManager.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

@available(*, deprecated, message: "POC version")
final class ViewHierarchySnapshottingManager {
    static let shared = ViewHierarchySnapshottingManager()

    // TODO: Andrey Fedorov - Replace with weak collection
    private weak var viewController: UIViewController?

    private init() {}

    func makeSnapshotView(afterScreenUpdates: Bool = false) -> UIView? {
        dispatchPrecondition(condition: .onQueue(.main))
        return viewController?.view.snapshotView(afterScreenUpdates: afterScreenUpdates)
    }

    func makeSnapshotViewImage(afterScreenUpdates: Bool = false, isOpaque: Bool = false) -> UIImage? {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let snapshotView = viewController?.view else {
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

    func makeSnapshotLayerImage(options: LayerSnapshotOptions = .default, isOpaque: Bool = false) -> UIImage? {
        dispatchPrecondition(condition: .onQueue(.main))

        let snapshotLayer: CALayer?
        switch options {
        case .default:
            snapshotLayer = viewController?.view.layer
        case .model:
            snapshotLayer = viewController?.view.layer.model()
        case .presentation:
            snapshotLayer = viewController?.view.layer.presentation()
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

    func register(_ viewController: UIViewController) {
        self.viewController = viewController
    }
}

// MARK: - Auxiliary types

extension ViewHierarchySnapshottingManager {
    enum LayerSnapshotOptions {
        /// The `CALayer` instance itself.
        case `default`
        case model
        case presentation
    }
}
