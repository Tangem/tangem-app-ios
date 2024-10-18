//
//  OnrampStepBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampStepBuilder {
    typealias IO = (input: OnrampInput, output: OnrampOutput)
    typealias ReturnValue = (step: OnrampStep, interactor: OnrampInteractor)

    func makeOnrampStep(io: IO, onrampManager: some OnrampManager, onrampAmountViewModel: OnrampAmountViewModel) -> ReturnValue {
        let interactor = makeOnrampInteractor(io: io, onrampManager: onrampManager)
        let viewModel = makeOnrampViewModel(onrampAmountViewModel: onrampAmountViewModel, interactor: interactor)
        let step = OnrampStep(viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension OnrampStepBuilder {
    func makeOnrampViewModel(
        onrampAmountViewModel: OnrampAmountViewModel,
        interactor: OnrampInteractor
    ) -> OnrampViewModel {
        OnrampViewModel(onrampAmountViewModel: onrampAmountViewModel, interactor: interactor)
    }

    func makeOnrampInteractor(io: IO, onrampManager: some OnrampManager) -> OnrampInteractor {
        CommonOnrampInteractor(input: io.input, output: io.output, onrampManager: onrampManager)
    }
}
