//
//  VisaOnboardingViewModelsBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 19.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemVisa

struct VisaOnboardingViewModelsBuilder {
    func buildWelcomeModel(
        activationStatus: VisaCardActivationStatus,
        isAccessCodeSet: Bool,
        cardImage: some Publisher<Image?, Never>,
        delegate: VisaOnboardingWelcomeDelegate
    ) -> VisaOnboardingWelcomeViewModel {
        let activationState: VisaOnboardingWelcomeViewModel.State
        let userName: String
        switch activationStatus {
        case .activated:
            // This step shouldn't appeared for activated card. Only biometry, notification and success screen
            activationState = .continueActivation
            userName = "Uninvited guest"
        case .activationStarted:
            userName = "IOS-8572"
            activationState = .continueActivation
        case .notStartedActivation:
            userName = "Visa Card"
            activationState = .newActivation
        case .blocked:
            userName = "Blocked"
            activationState = .newActivation
        }

        return .init(
            activationState: activationState,
            isAccessCodeSet: isAccessCodeSet,
            userName: userName,
            imagePublisher: cardImage,
            delegate: delegate
        )
    }

    func buildInProgressModel(activationRemoteState: VisaCardActivationRemoteState, delegate: VisaOnboardingInProgressDelegate) -> VisaOnboardingInProgressViewModel? {
        switch activationRemoteState {
        case .paymentAccountDeploying:
            return VisaOnboardingInProgressViewModel(state: .accountDeployment, delegate: delegate)
        case .waitingForActivationFinishing:
            return VisaOnboardingInProgressViewModel(state: .issuerProcessing, delegate: delegate)
        default:
            return nil
        }
    }
}
