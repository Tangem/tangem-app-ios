//
//  VisaOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 13/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct VisaOnboardingStepsBuilder {
    private let touId: String

    private var userWalletSavingSteps: [SingleCardOnboardingStep] {
        guard BiometricsUtil.isAvailable,
              !AppSettings.shared.saveUserWallets,
              !AppSettings.shared.askedToSaveUserWallets else {
            return []
        }

        return [.saveUserWallet]
    }

    init(touId: String) {
        self.touId = touId
    }
}

extension VisaOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }
        steps.append(contentsOf: userWalletSavingSteps)

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
