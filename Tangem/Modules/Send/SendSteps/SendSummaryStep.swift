//
//  SendSummaryStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendSummaryStep {
    private let _viewModel: SendSummaryViewModel
    private let interactor: SendSummaryInteractor
    private let tokenItem: TokenItem
    private let walletName: String

    init(
        viewModel: SendSummaryViewModel,
        interactor: SendSummaryInteractor,
        tokenItem: TokenItem,
        walletName: String
    ) {
        _viewModel = viewModel
        self.interactor = interactor
        self.tokenItem = tokenItem
        self.walletName = walletName
    }
}

// MARK: - SendStep

extension SendSummaryStep: SendStep {
    var title: String? { Localization.sendSummaryTitle(tokenItem.currencySymbol) }
    var subtitle: String? { walletName }

    var type: SendStepType { .summary }

    var viewModel: SendSummaryViewModel { _viewModel }

    func makeView(namespace: Namespace.ID) -> AnyView {
        AnyView(
            SendSummaryView(viewModel: _viewModel, namespace: namespace)
        )
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}

// MARK: - SendSummaryViewModelSetupable

extension SendSummaryStep: SendSummaryViewModelSetupable {
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
