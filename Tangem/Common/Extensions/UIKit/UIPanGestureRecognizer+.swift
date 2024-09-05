//
//  UIPanGestureRecognizer+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIPanGestureRecognizer {
    enum VerticalDirection {
        case up
        case down
    }

    func verticalDirection(in view: UIView?, relativeToGestureStartLocation startLocation: CGPoint) -> VerticalDirection? {
        let location = location(in: view)

        if startLocation.y > location.y {
            return .up
        }

        if startLocation.y < location.y {
            return .down
        }

        // Edge case (is it even possible?), unable to determine
        return nil
    }

    /// Based on this WWDC session https://developer.apple.com/videos/play/wwdc2018/803/
    func predictedEndLocation(
        in view: UIView?,
        atDecelerationRate decelerationRate: UIScrollView.DecelerationRate = .normal
    ) -> CGPoint {
        // Distance travelled after decelerating to zero velocity at a constant rate.
        func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
            // `UIScrollView.DecelerationRate` is measured in point/ms, but velocity of `UIPanGestureRecognizer`
            // is measured in points/s, so conversion needed
            return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
        }

        let currentLocation = location(in: view)
        let velocity = velocity(in: view)

        return CGPoint(
            x: currentLocation.x + project(initialVelocity: velocity.x, decelerationRate: decelerationRate.rawValue),
            y: currentLocation.y + project(initialVelocity: velocity.y, decelerationRate: decelerationRate.rawValue)
        )
    }
}
