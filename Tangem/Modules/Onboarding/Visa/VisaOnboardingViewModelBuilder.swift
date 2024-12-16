//
//  VisaOnboardingViewModelBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct VisaOnboardingViewModelBuilder {
    func makeOnboardingViewModel(onboardingInput: OnboardingInput, coordinator: VisaOnboardingRoutable) -> VisaOnboardingViewModel {
        let visaCardInput: VisaCardActivationInput
        switch onboardingInput.cardInput {
        case .cardId:
            fatalError("Invalid card input for Visa onboarding")
        case .cardInfo(let cardInfo):
            switch cardInfo.walletData {
            case .visa(let activationInput, _):
                visaCardInput = activationInput
            default:
                fatalError("Invalid card input for Visa onboarding")
            }
        case .userWalletModel(let userWalletModel):
            // TODO: IOS-8588
            fatalError("Invalid onboarding input for Visa")
        }
        let model = VisaOnboardingViewModel(
            input: onboardingInput,
            visaActivationManager: VisaActivationManagerFactory().make(
                cardInput: visaCardInput,
                tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
                urlSessionConfiguration: .default,
                logger: AppLog.shared
            ),
            coordinator: coordinator
        )

        return model
    }
}
