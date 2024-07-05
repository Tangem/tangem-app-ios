//
//  TwinOnboardingStepsBulder.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TwinOnboardingStepsBulder {
    private let cardId: String
    private let hasWallets: Bool
    private let twinData: TwinData
    private let isPushNotificationsAvailable: Bool

    private var otherSteps: [TwinsOnboardingStep] {
        var steps: [TwinsOnboardingStep] = []

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

    init(
        cardId: String,
        hasWallets: Bool,
        twinData: TwinData,
        isPushNotificationsAvailable: Bool
    ) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.twinData = twinData
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
    }
}

extension TwinOnboardingStepsBulder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true // TODO: remove this side-effect. Move into onboarding
            let twinPairNumber = twinData.series.pair.number
            steps.append(.intro(pairNumber: "#\(twinPairNumber)"))
        }

        if !hasWallets { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: otherSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .twins(steps)
        } else { // twin with created wallet
            if twinData.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: otherSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return .twins(steps)
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: otherSteps)
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .twins(steps)
                } else { // unknown twin, ready to use, go to main
                    steps.append(contentsOf: otherSteps)
                    return .twins(steps)
                }
            }
        }
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
