//
//  TwinOnboardingStepsBulder.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TwinOnboardingStepsBulder {
    private let card: CardDTO
    private let twinData: TwinData
    private let touId: String

    private var userWalletSavingSteps: [TwinsOnboardingStep] {
        guard BiometricsUtil.isAvailable,
              !AppSettings.shared.saveUserWallets,
              !AppSettings.shared.askedToSaveUserWallets else {
            return []
        }

        return [.saveUserWallet]
    }

    init(card: CardDTO, twinData: TwinData, touId: String) {
        self.card = card
        self.twinData = twinData
        self.touId = touId
    }
}

extension TwinOnboardingStepsBulder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true // TODO: remove this side-effect. Move into onboarding
            let twinPairNumber = twinData.series.pair.number
            steps.append(.intro(pairNumber: "#\(twinPairNumber)"))
        }

        if card.wallets.isEmpty { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: userWalletSavingSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .twins(steps)
        } else { // twin with created wallet
            if twinData.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: userWalletSavingSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return .twins(steps)
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(card.cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: userWalletSavingSteps)
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .twins(steps)
                } else { // unknown twin, ready to use, go to main
                    steps.append(contentsOf: userWalletSavingSteps)
                    return .twins(steps)
                }
            }
        }
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
