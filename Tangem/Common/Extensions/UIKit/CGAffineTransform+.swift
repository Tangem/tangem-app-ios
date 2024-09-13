//
//  CGAffineTransform+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGAffineTransform {
    /// Based on https://gist.github.com/wtsnz/f14575f4765568d2824ff350f521d1b3
    /// - Note: Anchor point works the same way as `CALayer.anchorPoint`: (0.5, 0.5) represents the center of the bounds rectangle.
    static func scaleTransform(
        for bounds: CGSize,
        scaledBy scale: CGPoint,
        aroundAnchorPoint relativeAnchorPoint: CGPoint
    ) -> CGAffineTransform {
        let anchorPoint = CGPoint(
            x: bounds.width * (relativeAnchorPoint.x - 0.5),
            y: bounds.height * (relativeAnchorPoint.y - 0.5)
        )

        return CGAffineTransform.identity
            .translatedBy(x: anchorPoint.x, y: anchorPoint.y)
            .scaledBy(x: scale.x, y: scale.y)
            .translatedBy(x: -anchorPoint.x, y: -anchorPoint.y)
    }
}
