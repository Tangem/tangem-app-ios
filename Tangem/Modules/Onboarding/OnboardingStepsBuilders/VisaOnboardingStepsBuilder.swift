//
//  VisaOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 13/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemVisa

struct VisaOnboardingStepsBuilder {
    private let cardId: String
    private let isPushNotificationsAvailable: Bool
    private let isAccessCodeSet: Bool
    private let activationStatus: VisaCardActivationStatus

    private var otherSteps: [VisaOnboardingStep] {
        var steps: [VisaOnboardingStep] = []

        if BiometricsUtil.isAvailable,
           !AppSettings.shared.saveUserWallets,
           !AppSettings.shared.askedToSaveUserWallets {
            steps.append(.saveUserWallet)
        }

        if isPushNotificationsAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }

    private var approveSteps: [VisaOnboardingStep] {
        [
            .selectWalletForApprove,
            .approveUsingTangemWallet,
        ]
    }

    init(
        cardId: String,
        isPushNotificationsAvailable: Bool,
        isAccessCodeSet: Bool,
        activationStatus: VisaCardActivationStatus
    ) {
        self.cardId = cardId
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
        self.isAccessCodeSet = isAccessCodeSet
        self.activationStatus = activationStatus
    }
}

extension VisaOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [VisaOnboardingStep]()

        if !activationStatus.isActivated {
            steps.append(.welcome)

            if !isAccessCodeSet {
                steps.append(.accessCode)
            }

            steps.append(contentsOf: approveSteps)
        }

        steps.append(contentsOf: otherSteps)

        return .visa(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
