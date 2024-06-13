//
//  TwinsOnboardingCardLayout.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum TwinOnboardingCardLayout: OnboardingCardFrameCalculator {
    case first
    case second

    var cardHeightWidthRatio: CGFloat { 0.519 }

    func animSettings(at step: TwinsOnboardingStep, containerSize: CGSize, stackCalculator: StackCalculator, animated: Bool) -> AnimatedViewSettings {
        switch (step, self) {
        case (.first, _), (.second, .second), (.third, .first):
            return .init(
                targetSettings: stackCalculator.cardSettings(at: stackIndex(at: step)),
                intermediateSettings: nil
            )
        case (.second, .first), (.third, .second):
            return .init(
                targetSettings: stackCalculator.cardSettings(at: stackIndex(at: step)),
                intermediateSettings: animated ? stackCalculator.prehideAnimSettings : nil
            )
        case (.done, _), (.topup, _):
            var settings = stackCalculator.cardSettings(at: stackIndex(at: step))
            settings.scale *= 0.5
            settings.offset = offset(at: step, in: containerSize)
            return .init(targetSettings: settings, intermediateSettings: nil)
        default:
            return .init(
                targetSettings: CardAnimSettings(
                    frame: frame(for: step, containerSize: containerSize),
                    offset: offset(at: step, in: containerSize),
                    scale: 1.0,
                    opacity: opacity(at: step),
                    zIndex: zIndex(at: step),
                    rotationAngle: rotationAngle(at: step),
                    animType: animated ? .default : .noAnim
                ),
                intermediateSettings: nil
            )
        }
    }

    func cardFrameMinHorizontalPadding(at step: TwinsOnboardingStep) -> CGFloat {
        switch (step, self) {
        case (.pushNotifications, _), (.saveUserWallet, _), (.success, _): return 0
        case (.intro, _), (.alert, _): return 75
        case (.first, .first), (.second, .second), (.third, .first): return 80
        case (.first, .second), (.second, .first), (.third, .second): return 120
        case (.done, _), (.topup, _):
            return 220
        }
    }

    func cardHeightToContainerHeightRatio(for step: TwinsOnboardingStep) -> CGFloat {
        switch (step, self) {
        case (.pushNotifications, _), (.saveUserWallet, _), (.success, _): return 0
        case (.intro, _), (.alert, _): return 0.431
        case (.first, .first), (.second, .second), (.third, .first):
            return 0.454
        case (.first, .second), (.second, .first), (.third, .second):
            return 0.395
        case (.done, _), (.topup, _):
            return 0.246
        }
    }

    private func offset(at step: TwinsOnboardingStep, in container: CGSize) -> CGSize {
        let containerHeight = container.height
        switch (step, self) {
        case (.pushNotifications, _), (.saveUserWallet, _), (.success, _): return .zero
        case (.intro, .first), (.alert, .first):
            let heightOffset = containerHeight * 0.08
            let widthOffset = container.width * 0.131
            return .init(width: -widthOffset, height: -heightOffset)
        case (.intro, .second), (.alert, .second):
            let heightOffset = containerHeight * 0.183
            let widthOffset = container.width * 0.131
            return .init(width: widthOffset, height: heightOffset)
        case (.first, .first), (.second, .second), (.third, .first):
//            return .init(width: 0, height: -containerHeight * 0.128)
            fallthrough
        case (.first, .second), (.second, .first), (.third, .second):
//            return .init(width: 0, height: containerHeight * 0.095)
            return .zero
        case (.done, .first), (.topup, .first):
            return .init(width: 0, height: -containerHeight * 0.12)
        case (.done, .second), (.topup, .second):
            return .init(width: 0, height: -containerHeight * 0.08)
        }
    }

    private func rotationAngle(at step: TwinsOnboardingStep) -> Angle {
        switch (step, self) {
        case (.intro, _), (.alert, _): return Angle(degrees: -2)
        default: return .zero
        }
    }

    private func zIndex(at step: TwinsOnboardingStep) -> Double {
        let topCardIndex: Double = 10
        let lowerCardIndex: Double = 9
        switch (step, self) {
        case (.second, .first): return lowerCardIndex
        case (.second, .second): return topCardIndex
        case (_, .first): return topCardIndex
        case (_, .second): return lowerCardIndex
        }
    }

    private func stackIndex(at step: TwinsOnboardingStep) -> Int {
        let topCard = 0
        let lowerCard = 1
        switch (step, self) {
        case (.second, .first): return lowerCard
        case (.second, .second): return topCard
        case (_, .first): return topCard
        case (_, .second): return lowerCard
        }
    }

    private func opacity(at step: TwinsOnboardingStep) -> Double {
        switch (step, self) {
        case (.intro, _), (.alert, _): return 1
        case (.first, .second), (.second, .first), (.third, .second):
            return 0.9
        case (.second, .second): return 1
        case (_, .second): return 0
        case (_, .first): return 1
        }
    }
}
