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
    func makeSnapshotView(afterScreenUpdates: Bool) -> UIView?
    func makeSnapshotViewImage(afterScreenUpdates: Bool, isOpaque: Bool) -> UIImage?
    func makeSnapshotLayerImage(options: CALayerSnapshotOptions, isOpaque: Bool) -> UIImage?
}

// MARK: - Convenience extensions

extension ViewHierarchySnapshotting {
    func makeSnapshotView() -> UIView? {
        return makeSnapshotView(afterScreenUpdates: false)
    }

    func makeSnapshotViewImage() -> UIImage? {
        return makeSnapshotViewImage(afterScreenUpdates: false, isOpaque: false)
    }

    func makeSnapshotLayerImage() -> UIImage? {
        return makeSnapshotLayerImage(options: .default, isOpaque: false)
    }
}
