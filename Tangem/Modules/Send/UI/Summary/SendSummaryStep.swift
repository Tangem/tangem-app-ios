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
    private let input: SendSummaryInput
    private let _title: String?
    private let _subtitle: String?

    init(
        viewModel: SendSummaryViewModel,
        input: SendSummaryInput,
        title: String?,
        subtitle: String?
    ) {
        self.viewModel = viewModel
        self.input = input
        _title = title
        _subtitle = subtitle
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendSummaryStep: SendStep {
    var title: String? { _title }

    var subtitle: String? { _subtitle }

    var type: SendStepType { .summary(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        input.isReadyToSendPublisher.eraseToAnyPublisher()
    }
}
