//
//  SendDestinationStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendDestinationStep {
    private let viewModel: SendDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let sendFeeInteractor: SendFeeInteractor
    private let tokenItem: TokenItem

    init(
        viewModel: SendDestinationViewModel,
        interactor: any SendDestinationInteractor,
        sendFeeInteractor: any SendFeeInteractor,
        tokenItem: TokenItem
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
        self.tokenItem = tokenItem
    }

    func set(stepRouter: SendDestinationStepRoutable) {
        viewModel.stepRouter = stepRouter
    }
}

// MARK: - SendStep

extension SendDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .destination(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var navigationTrailingViewType: SendStepNavigationTrailingViewType? {
        .qrCodeButton { [weak self] in
            self?.viewModel.scanQRCode()
        }
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.allFieldsIsValid.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        if step.type.isSummary {
            Analytics.log(.sendScreenReopened, params: [.source: .address])
        } else {
            Analytics.log(.sendAddressScreenOpened)
        }
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
