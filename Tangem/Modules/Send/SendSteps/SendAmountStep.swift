//
//  SendAmountStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendAmountStep {
    private let viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let sendFeeLoader: SendFeeLoader

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeLoader: SendFeeLoader
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeLoader = sendFeeLoader
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        if step.type.isSummary {
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        } else {
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func willDisappear(next step: SendStep) {
        UIApplication.shared.endEditing()

        guard step.type.isSummary else {
            return
        }

        sendFeeLoader.updateFees()
    }
}
