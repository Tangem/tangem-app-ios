//
//  NoteOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct NoteOnboardingStepsBuilder {
    private let cardId: String
    private let hasWallets: Bool

    private var otherSteps: [SingleCardOnboardingStep] {
        var steps: [SingleCardOnboardingStep] = []

        if BiometricsUtil.isAvailable,
           !AppSettings.shared.saveUserWallets,
           !AppSettings.shared.askedToSaveUserWallets {
            steps.append(.saveUserWallet)
        }

        if PushNotificationsProvider.isAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }

    init(cardId: String, hasWallets: Bool) {
        self.cardId = cardId
        self.hasWallets = hasWallets
    }
}

extension NoteOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if hasWallets {
            if !AppSettings.shared.cardsStartedActivation.contains(cardId) {
                steps.append(contentsOf: otherSteps)
            } else {
                steps.append(contentsOf: otherSteps + [.topup, .successTopup])
            }
        } else {
            steps.append(contentsOf: [.createWallet] + otherSteps + [.topup, .successTopup])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
