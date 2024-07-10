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

    init(
        viewModel: StakingValidatorsViewModel,
        interactor: StakingValidatorsInteractor
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
    }
}

// MARK: - SendStep

extension StakingValidatorsStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .validators(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: false) // TODO: https://tangem.atlassian.net/browse/IOS-7105
    }
}
