//
//  UIPanGestureRecognizer+Value.swift
//  Tangem
//
//  Created by Andrey Fedorov on 03.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIPanGestureRecognizer {
    /// This API is meant to mirror `DragGesture.Value` as that has no accessible initializers.
    struct Value {
        /// The time associated with the current event.
        let time: Date

        /// The location of the current event.
        let location: CGPoint

        /// The location of the first event.
        let startLocation: CGPoint

        /// The current drag velocity.
        let velocity: CGPoint

        /// The total translation from the first event to the current event. Equivalent to `location - startLocation`.
        var translation: CGSize {
            return CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }

        /// A prediction of where the final location would be if dragging stopped now, based on the current drag velocity.
        var predictedEndLocation: CGPoint {
            let endTranslation = predictedEndTranslation
            return CGPoint(x: location.x + endTranslation.width, y: location.y + endTranslation.height)
        }

        /// A prediction, based on the current drag velocity, of what the final translation will be if dragging stopped now.
        var predictedEndTranslation: CGSize {
            return CGSize(
                width: estimatedTranslation(fromVelocity: velocity.x),
                height: estimatedTranslation(fromVelocity: velocity.y)
            )
        }
    }
}

// MARK: - Convenience extensions

private extension UIPanGestureRecognizer.Value {
    private func estimatedTranslation(fromVelocity velocity: CGFloat) -> CGFloat {
        // This is a guess. I couldn't find any documentation anywhere on what this should be
        let acceleration = 500.0
        let timeToStop = velocity / acceleration
        return velocity * timeToStop / 2.0
    }
}
