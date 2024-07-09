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
    let viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let sendFeeInteractor: SendFeeInteractor

    var auxiliaryViewAnimatable: AuxiliaryViewAnimatable {
        viewModel
    }

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount }

    var viewType: SendStepViewType { .amount(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func willDisappear(next step: SendStep) {
        UIApplication.shared.endEditing()

        guard step.type == .summary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
