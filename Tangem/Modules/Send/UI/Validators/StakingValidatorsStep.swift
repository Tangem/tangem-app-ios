//
//  StakingValidatorsStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class StakingValidatorsStep {
    private let viewModel: StakingValidatorsViewModel
    private let interactor: StakingValidatorsInteractor
    private let sendFeeLoader: SendFeeLoader

    init(
        viewModel: StakingValidatorsViewModel,
        interactor: StakingValidatorsInteractor,
        sendFeeLoader: SendFeeLoader
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeLoader = sendFeeLoader
    }
}

// MARK: - SendStep

extension StakingValidatorsStep: SendStep {
    var title: String? { Localization.stakingValidator }

    var type: SendStepType { .validators(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeLoader.updateFees()
    }
}
