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

    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func makeOnrampStep(
        io: IO,
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel
    ) -> ReturnValue {
        let interactor = makeOnrampInteractor(io: io)
        let viewModel = makeOnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            interactor: interactor
        )
        let step = OnrampStep(tokenItem: walletModel.tokenItem, viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension OnrampStepBuilder {
    func makeOnrampViewModel(
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        interactor: OnrampInteractor
    ) -> OnrampViewModel {
        OnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            interactor: interactor
        )
    }

    func makeOnrampInteractor(io: IO) -> OnrampInteractor {
        CommonOnrampInteractor(input: io.input, output: io.output)
    }
}
