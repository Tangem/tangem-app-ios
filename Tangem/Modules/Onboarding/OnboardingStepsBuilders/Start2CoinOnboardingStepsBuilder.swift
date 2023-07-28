//
//  Start2CoinOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct Start2CoinOnboardingStepsBuilder {
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

    init(hasWallets: Bool, touId: String) {
        self.hasWallets = hasWallets
        self.touId = touId
    }
}

extension Start2CoinOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if hasWallets {
            steps.append(contentsOf: userWalletSavingSteps)
        } else {
            steps.append(contentsOf: [.createWallet] + userWalletSavingSteps + [.success])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
