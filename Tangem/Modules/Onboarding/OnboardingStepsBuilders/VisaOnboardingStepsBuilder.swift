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
}

extension VisaOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        steps.append(contentsOf: otherSteps)

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
