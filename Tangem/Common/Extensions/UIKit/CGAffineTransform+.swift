//
//  CGAffineTransform+.swift
//  Tangem
//
//  Created by m3g0byt3 on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGAffineTransform {
    /// Based on https://gist.github.com/wtsnz/f14575f4765568d2824ff350f521d1b3
    static func scaleTransform(
        for bounds: CGSize,
        scaledBy scale: CGPoint,
        aroundAnchorPoint relativeAnchorPoint: CGPoint,
        translationCoefficient: CGFloat = 1.0
    ) -> CGAffineTransform {
        let anchorPoint = CGPoint(
            x: bounds.width * relativeAnchorPoint.x * translationCoefficient,
            y: bounds.height * relativeAnchorPoint.y * translationCoefficient
        )

        return CGAffineTransform.identity
            .translatedBy(x: anchorPoint.x, y: anchorPoint.y)
            .scaledBy(x: scale.x, y: scale.y)
            .translatedBy(x: -anchorPoint.x, y: -anchorPoint.y)
    }
}
