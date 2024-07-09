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
    private let sendAmountViewModel: SendAmountViewModel
    private let sendFeeInteractor: SendFeeInteractor
    private let tokenItem: TokenItem

    var auxiliaryViewAnimatable: AuxiliaryViewAnimatable {
        viewModel
    }

    init(
        viewModel: SendDestinationViewModel,
        interactor: any SendDestinationInteractor,
        sendAmountViewModel: SendAmountViewModel,
        sendFeeInteractor: any SendFeeInteractor,
        tokenItem: TokenItem
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendAmountViewModel = sendAmountViewModel
        self.sendFeeInteractor = sendFeeInteractor
        self.tokenItem = tokenItem
    }

//    func set(router: SendDestinationRoutable) {
//        viewModel.router = router
//    }
}

// MARK: - SendStep

extension SendDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .destination }

    var viewType: SendStepViewType { .destination(viewModel) }

    var navigationTrailingViewType: SendStepNavigationTrailingViewType? {
        .qrCodeButton { [weak self] in
            self?.viewModel.scanQRCode()
        }
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.destinationValid.eraseToAnyPublisher()
    }

    func willDisappear(next step: SendStep) {
        guard step.type == .summary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
