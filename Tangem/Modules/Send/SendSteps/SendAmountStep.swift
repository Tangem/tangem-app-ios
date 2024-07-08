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
    private let _viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let sendFeeInteractor: SendFeeInteractor

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor
    ) {
        _viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount }

    var viewModel: SendAmountViewModel { _viewModel }

    func makeView(namespace: Namespace.ID) -> AnyView {
        AnyView(
            SendAmountView(
                viewModel: viewModel,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
        )
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.errorPublisher.map { $0 == nil }.eraseToAnyPublisher()
    }

    func willClose(next step: any SendStep) {
        sendFeeInteractor.updateFees()
    }
}
