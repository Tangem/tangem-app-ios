//
//  ViewHierarchySnapshotting.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

/// - Note: Always choose proper snapshotting methods; they differ in terms of capabilities and performance.
/// See https://developer.apple.com/library/archive/qa/qa1817/_index.html for details
protocol ViewHierarchySnapshotting {
    func makeSnapshotView(afterScreenUpdates: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIView?
    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool, overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIImage?
    /// - Note: Core Animation ignores `view.overrideUserInterfaceStyle` setting, impossible to override user interface style.
    func makeSnapshotLayerImage(options: CALayerSnapshotOptions, isOpaque: Bool) -> UIImage?
}

// MARK: - Convenience extensions

extension ViewHierarchySnapshotting {
    func makeSnapshotView() -> UIView? {
        return makeSnapshotView(afterScreenUpdates: false, overrideUserInterfaceStyle: nil)
    }

    func makeSnapshotViewImage() -> UIImage? {
        return makeSnapshotViewImage(afterScreenUpdates: false, isOpaque: false, overrideUserInterfaceStyle: nil)
    }

    func makeSnapshotLayerImage() -> UIImage? {
        return makeSnapshotLayerImage(options: .default, isOpaque: false)
    }
}
