//
//  UIPanGestureRecognizer+.swift
//  Tangem
//
//  Created by m3g0byt3 on 15.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIPanGestureRecognizer {
    func predictedTranslation(
        in view: UIView?,
        atDecelerationRate decelerationRate: UIScrollView.DecelerationRate = .normal
    ) -> CGPoint {
        assert(decelerationRate.rawValue < 1.0, "Invalid deceleration rate \(decelerationRate.rawValue)")

        let normalizedDecelerationRate = decelerationRate.rawValue / (1.0 - decelerationRate.rawValue)
        let translation = translation(in: view)
        let velocity = velocity(in: view)

        // `UIScrollView.DecelerationRate` is measured in point/ms, but velocity of `UIPanGestureRecognizer`
        // is measured in points/s, so conversion needed
        let velocityMultiplier = 0.001
        let convertedVelocity = CGPoint(
            x: velocity.x * velocityMultiplier,
            y: velocity.y * velocityMultiplier
        )

        return CGPoint(
            x: translation.x + convertedVelocity.x * normalizedDecelerationRate,
            y: translation.y + convertedVelocity.y * normalizedDecelerationRate
        )
    }
}
