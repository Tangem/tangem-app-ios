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
        activationStatus: VisaCardActivationLocalState,
        isAccessCodeSet: Bool,
        cardImage: some Publisher<Image?, Never>,
        delegate: VisaOnboardingWelcomeDelegate
    ) -> VisaOnboardingWelcomeViewModel {
        let activationState: VisaOnboardingWelcomeViewModel.State
        switch activationStatus {
        case .activated:
            // This step shouldn't appeared for activated card. Only biometry, notification and success screen
            activationState = .continueActivation
        case .activationStarted:
            activationState = .continueActivation
        case .notStartedActivation:
            activationState = .newActivation
        case .blocked:
            activationState = .newActivation
        }

        return .init(
            activationState: activationState,
            isAccessCodeSet: isAccessCodeSet,
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
