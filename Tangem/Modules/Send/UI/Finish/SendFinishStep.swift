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

    init(viewModel: SendFinishViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - SendStep

extension SendFinishStep: SendStep {
    var title: String? { nil }

    var type: SendStepType { .finish(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}
