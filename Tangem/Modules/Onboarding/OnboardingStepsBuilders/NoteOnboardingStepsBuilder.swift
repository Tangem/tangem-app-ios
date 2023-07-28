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
    private let touId: String

    private var userWalletSavingSteps: [SingleCardOnboardingStep] {
        guard BiometricsUtil.isAvailable,
              !AppSettings.shared.saveUserWallets,
              !AppSettings.shared.askedToSaveUserWallets else {
            return []
        }

        return [.saveUserWallet]
    }

    init(cardId: String, hasWallets: Bool, touId: String) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.touId = touId
    }
}

extension NoteOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if hasWallets {
            if !AppSettings.shared.cardsStartedActivation.contains(cardId) {
                steps.append(contentsOf: userWalletSavingSteps)
            } else {
                steps.append(contentsOf: userWalletSavingSteps + [.topup, .successTopup])
            }
        } else {
            steps.append(contentsOf: [.createWallet] + userWalletSavingSteps + [.topup, .successTopup])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
