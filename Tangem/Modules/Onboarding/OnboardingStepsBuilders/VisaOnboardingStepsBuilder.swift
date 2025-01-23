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
            .approveUsingWalletConnect,
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

    private func buildSteps(for state: VisaCardActivationRemoteState) -> [VisaOnboardingStep] {
        var steps = [VisaOnboardingStep]()
        switch state {
        case .cardWalletSignatureRequired:
            steps.append(.welcomeBack(isAccessCodeSet: isAccessCodeSet))

            if !isAccessCodeSet {
                steps.append(.accessCode)
            }

            fallthrough
        case .customerWalletSignatureRequired:
            steps.append(contentsOf: approveSteps)
            fallthrough
        case .paymentAccountDeploying:
            steps.append(contentsOf: [.inProgress, .pinSelection])
        case .waitingPinCode:
            steps.append(contentsOf: [.pinSelection, .inProgress])
        case .waitingForActivationFinishing:
            steps.append(.inProgress)
        case .activated, .blockedForActivation:
            // Card shouldn't be able to reach onboarding with this state. Anyway we don't need to add any steps
            return []
        }

        return steps
    }
}

extension VisaOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [VisaOnboardingStep]()

        switch activationStatus {
        case .activated:
            break
        case .activationStarted(_, _, let activationRemoteState):
            steps.append(contentsOf: buildSteps(for: activationRemoteState))
        case .notStartedActivation:
            steps.append(contentsOf: [.welcome, .accessCode] + approveSteps)
        case .blocked:
            return .visa([])
        }

        steps.append(contentsOf: otherSteps)

        steps.append(.success)

        return .visa(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
