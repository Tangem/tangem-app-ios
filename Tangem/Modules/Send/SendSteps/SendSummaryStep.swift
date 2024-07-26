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
    private let viewModel: SendSummaryViewModel
    private let interactor: SendSummaryInteractor
    private let input: SendSummaryInput
    private let tokenItem: TokenItem
    private let walletName: String

    init(
        viewModel: SendSummaryViewModel,
        interactor: SendSummaryInteractor,
        input: SendSummaryInput,
        tokenItem: TokenItem,
        walletName: String
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.tokenItem = tokenItem
        self.input = input
        self.walletName = walletName
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendSummaryStep: SendStep {
    var title: String? { Localization.sendSummaryTitle(tokenItem.currencySymbol) }

    var subtitle: String? { walletName }

    var type: SendStepType { .summary(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        input.transactionPublisher.map { $0 != nil }.eraseToAnyPublisher()
    }
}
