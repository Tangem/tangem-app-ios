//
//  CardsInfoPagerAnimationFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerAnimationFactory {
    private let hasValidIndexToSelect: Bool
    private let currentPageSwitchProgress: CGFloat
    private let minRemainingPageSwitchProgress: CGFloat
    private let pageSwitchAnimationDuration: TimeInterval

    init(
        hasValidIndexToSelect: Bool,
        currentPageSwitchProgress: CGFloat,
        minRemainingPageSwitchProgress: CGFloat,
        pageSwitchAnimationDuration: TimeInterval
    ) {
        self.hasValidIndexToSelect = hasValidIndexToSelect
        self.currentPageSwitchProgress = currentPageSwitchProgress
        self.minRemainingPageSwitchProgress = minRemainingPageSwitchProgress
        self.pageSwitchAnimationDuration = pageSwitchAnimationDuration
    }

    func makeHorizontalScrollAnimation(
        totalWidth: CGFloat,
        dragGestureVelocity: CGSize,
        pageHasBeenSwitched: Bool
    ) -> Animation {
        let remainingPageSwitchProgress = pageHasBeenSwitched
            ? 1.0 - currentPageSwitchProgress
            : currentPageSwitchProgress
        let minRemainingPageSwitchProgress = minRemainingPageSwitchProgress
        var remainingPageSwitchProgressIsTooSmall = false
        let remainingWidth = totalWidth * remainingPageSwitchProgress
        let horizontalDragGestureVelocity = abs(dragGestureVelocity.width)
        var animationSpeed = 1.0

        if horizontalDragGestureVelocity > 0.0 {
            let gestureDrivenAnimationDuration = remainingWidth / horizontalDragGestureVelocity
            let remainingAnimationDuration = pageSwitchAnimationDuration * remainingPageSwitchProgress
            if gestureDrivenAnimationDuration < remainingAnimationDuration {
                // `sqrt(2.0)` constant is used to reduce 'sharpness' of the gesture-driven animation
                animationSpeed = pageSwitchAnimationDuration / (gestureDrivenAnimationDuration * sqrt(2.0))
            } else {
                // Horizontal velocity of the drag gesture is slower than the velocity of the default
                // animation with remaining duration, therefore animation speed is calculated based
                // on current page switching progress
                animationSpeed = pageSwitchProgressDrivenAnimationSpeed(
                    remainingPageSwitchProgress: remainingPageSwitchProgress
                )
                remainingPageSwitchProgressIsTooSmall = remainingPageSwitchProgress < minRemainingPageSwitchProgress
            }
        } else {
            // Horizontal velocity of the drag gesture is zero, therefore animation speed
            // is calculated based on current page switching progress
            animationSpeed = pageSwitchProgressDrivenAnimationSpeed(
                remainingPageSwitchProgress: remainingPageSwitchProgress
            )
            remainingPageSwitchProgressIsTooSmall = remainingPageSwitchProgress < minRemainingPageSwitchProgress
        }

        if !hasValidIndexToSelect || remainingPageSwitchProgressIsTooSmall {
            // 'sharpness' of the animations is reduced in two cases:
            //
            // 1. If there is no valid next/previous index to select (i.e. when we are at
            // the first/last page and we're trying to switch to either `selectedIndexLowerBound - 1`
            // or `selectedIndexUpperBound + 1` index)
            //
            // 2. There is not enough remaining page switch progress left to make nice-looking animations
            animationSpeed = clamp(animationSpeed, min: 1.0, max: 3.0)
        }

        let springAnimationResponse = 0.55
        let springAnimationDampingFraction = 0.78

        // It's impossible to set the duration of spring animation to a particular value precisely,
        // so this speed is approximate
        let approximateDefaultAnimationSpeed = springAnimationResponse / pageSwitchAnimationDuration

        return .spring(response: springAnimationResponse, dampingFraction: springAnimationDampingFraction)
            .speed(approximateDefaultAnimationSpeed)
            .speed(animationSpeed)
    }

    /// Speed up page switching animations based on the already elapsed horizontal distance.
    ///
    /// For example, if the user has already scrolled 2/3 of a horizontal distance using the drag gesture,
    /// the remaining 1/3 of the distance will be animated using 1/3 of the original duration of the animation
    private func pageSwitchProgressDrivenAnimationSpeed(
        remainingPageSwitchProgress: CGFloat
    ) -> CGFloat {
        guard remainingPageSwitchProgress > 0.0 else { return 1.0 }

        return 1.0 / remainingPageSwitchProgress
    }
}
