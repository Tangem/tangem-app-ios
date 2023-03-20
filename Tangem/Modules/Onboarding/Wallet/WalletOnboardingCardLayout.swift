//
//  WalletOnboardingCardLayout.swift
//  Tangem
//
//  Created by Andrew Son on 22.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WalletOnboardingCardLayout {
    case origin
    case firstBackup
    case secondBackup

    var cardFanStackIndex: Int {
        switch self {
        case .origin: return 0
        case .firstBackup: return 1
        case .secondBackup: return 2
        }
    }

    func animSettings(at step: WalletOnboardingStep, in container: CGSize, fanStackCalculator: FanStackCalculator, animated: Bool) -> AnimatedViewSettings {
        switch (self, step) {
        case (_, .selectBackupCards):
            return .init(
                targetSettings: fanStackCalculator.settingsForCard(at: cardFanStackIndex),
                intermediateSettings: nil
            )
        case (_, .claim), (_, .successClaim):
            return .init(
                targetSettings: SingleCardOnboardingCardsLayout.main.cardAnimSettings(for: .topup, containerSize: container, animated: animated),
                intermediateSettings: nil
            )
        case (_, .success):
            return .zero
        case (.origin, _), (.firstBackup, _), (.secondBackup, _):
            let targetSettings = CardAnimSettings(
                frame: frame(for: step, containerSize: container),
                offset: offset(at: step, in: container),
                scale: scale(at: step, in: container),
                opacity: opacity(at: step, in: container),
                zIndex: zIndex(at: step),
                rotationAngle: rotation(at: step, in: container)
            )

            return .init(
                targetSettings: targetSettings,
                intermediateSettings: nil
            )
        }
    }

    func offset(at step: WalletOnboardingStep, in container: CGSize) -> CGSize {
        switch (self, step) {
        case (_, .createWallet), (_, .createWalletSelector), (_, .scanPrimaryCard):
            return .init(width: 0, height: container.height * 0.089)
        case (.origin, .backupIntro):
            return .init(width: 1, height: container.height * 0.034)
        case (.firstBackup, .backupIntro):
            return .init(width: container.width * 0.413, height: container.height * 0.128)
        case (.secondBackup, .backupIntro):
            return .init(width: -container.width * 0.384, height: container.height * 0.025)
        default:
            return .zero
        }
    }

    func scale(at step: WalletOnboardingStep, in container: CGSize) -> CGFloat {
        1
    }

    func zIndex(at step: WalletOnboardingStep) -> Double {
        switch (self, step) {
        case (.origin, _): return 100
        case (.firstBackup, .backupIntro): return 101
        case (.secondBackup, _): return 98
        case (.firstBackup, _): return 99
        }
    }

    func opacity(at step: WalletOnboardingStep, in container: CGSize) -> Double {
        switch (self, step) {
        case (.secondBackup, .createWallet), (_, .success): return 0
        default:
            return 1
        }
    }

    func rotation(at step: WalletOnboardingStep, in container: CGSize) -> Angle {
        switch (self, step) {
        case (.origin, .backupIntro):
            return Angle(degrees: 105)
        case (.firstBackup, .backupIntro), (.secondBackup, .backupIntro):
            return Angle(degrees: 73)
        default: return .zero
        }
    }
}

extension WalletOnboardingCardLayout: OnboardingCardFrameCalculator {
    typealias Step = WalletOnboardingStep

    var cardHeightWidthRatio: CGFloat {
        0.629
    }

    func cardHeightToContainerHeightRatio(for step: WalletOnboardingStep) -> CGFloat {
        switch step {
        case .createWallet, .createWalletSelector, .scanPrimaryCard:
            return 0.453
        case .selectBackupCards:
            return 0.318
        case .backupIntro:
            return 0.371
        default:
            return 0.5
        }
    }

    func cardFrameMinHorizontalPadding(at step: WalletOnboardingStep) -> CGFloat {
        switch step {
        case .createWallet, .createWalletSelector, .scanPrimaryCard: return 60
        case .backupIntro: return 146
        case .selectBackupCards: return 143
        default: return 0
        }
    }
}
