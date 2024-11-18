//
//  OnrampAmountBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 30.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampAmountBuilder {
    typealias IO = (input: OnrampAmountInput, output: OnrampAmountOutput)
    typealias ReturnValue = (viewModel: OnrampAmountViewModel, interactor: OnrampAmountInteractor)

    private let walletModel: WalletModel
    private let builder: SendDependenciesBuilder

    init(walletModel: WalletModel, builder: SendDependenciesBuilder) {
        self.walletModel = walletModel
        self.builder = builder
    }

    func makeOnrampAmountViewModel(io: IO, onrampProvidersInput: OnrampProvidersInput, coordinator: OnrampAmountRoutable) -> ReturnValue {
        let interactor = makeOnrampAmountInteractor(io: io, onrampProvidersInput: onrampProvidersInput)
        let viewModel = OnrampAmountViewModel(
            tokenItem: walletModel.tokenItem,
            interactor: interactor,
            coordinator: coordinator
        )

        return (viewModel: viewModel, interactor: interactor)
    }

    func makeOnrampAmountCompactViewModel(
        onrampAmountInput: OnrampAmountInput,
        onrampProvidersInput: OnrampProvidersInput
    ) -> OnrampAmountCompactViewModel {
        OnrampAmountCompactViewModel(
            onrampAmountInput: onrampAmountInput,
            onrampProvidersInput: onrampProvidersInput,
            tokenItem: walletModel.tokenItem
        )
    }
}

// MARK: - Private

private extension OnrampAmountBuilder {
    func makeOnrampAmountInteractor(io: IO, onrampProvidersInput: OnrampProvidersInput) -> OnrampAmountInteractor {
        CommonOnrampAmountInteractor(
            input: io.input,
            output: io.output,
            onrampProvidersInput: onrampProvidersInput,
            tokenItem: walletModel.tokenItem
        )
    }
}
