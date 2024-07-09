//
//  SendFinishStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendFinishStep {
    private let viewModel: SendFinishViewModel
    private let sendFeeInteractor: SendFeeInteractor

    init(
        viewModel: SendFinishViewModel,
        sendFeeInteractor: SendFeeInteractor
    ) {
        self.viewModel = viewModel
        self.sendFeeInteractor = sendFeeInteractor
    }
}

// MARK: - SendStep

extension SendFinishStep: SendStep {
    var title: String? { nil }

    var type: SendStepType { .finish }

    var viewType: SendStepViewType { .finish(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}

// MARK: - SendFinishViewModelSetupable

extension SendFinishStep: SendFinishViewModelSetupable {
    func setup(sendFinishInput: any SendFinishInput) {
        viewModel.setup(sendFinishInput: sendFinishInput)
    }

    func setup(sendDestinationInput: any SendDestinationInput) {
        viewModel.setup(sendDestinationInput: sendDestinationInput)
    }

    func setup(sendAmountInput: any SendAmountInput) {
        viewModel.setup(sendAmountInput: sendAmountInput)
    }

    func setup(sendFeeInteractor: any SendFeeInteractor) {
        viewModel.setup(sendFeeInteractor: sendFeeInteractor)
    }
}
