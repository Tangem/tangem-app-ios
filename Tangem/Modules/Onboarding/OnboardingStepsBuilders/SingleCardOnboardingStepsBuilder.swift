//
//  SingleCardOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SingleCardOnboardingStepsBuilder {
    private let cardId: String
    private let hasWallets: Bool
    private let touId: String
    private let isMultiCurrency: Bool

    private var userWalletSavingSteps: [SingleCardOnboardingStep] {
        guard BiometricsUtil.isAvailable,
              !AppSettings.shared.saveUserWallets,
              !AppSettings.shared.askedToSaveUserWallets else {
            return []
        }

        return [.saveUserWallet]
    }

    private var addTokensSteps: [SingleCardOnboardingStep] {
        isMultiCurrency && FeatureProvider.isAvailable(.markets) ? [.addTokens] : []
    }

    init(cardId: String, hasWallets: Bool, touId: String, isMultiCurrency: Bool) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.touId = touId
        self.isMultiCurrency = isMultiCurrency
    }
}

extension SingleCardOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if hasWallets {
            if AppSettings.shared.cardsStartedActivation.contains(cardId) {
                steps.append(contentsOf: userWalletSavingSteps + addTokensSteps + [.success])
            } else {
                steps.append(contentsOf: userWalletSavingSteps)
            }
        } else {
            steps.append(contentsOf: [.createWallet] + userWalletSavingSteps + addTokensSteps + [.success])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
