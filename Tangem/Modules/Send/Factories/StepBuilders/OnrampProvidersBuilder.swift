//
//  OnrampProvidersBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampProvidersBuilder {
    typealias IO = (input: OnrampProvidersInput, output: OnrampProvidersOutput)
    typealias ReturnValue = OnrampProvidersViewModel

    private let io: IO
    private let tokenItem: TokenItem
    private let paymentMethodsInput: OnrampPaymentMethodsInput

    init(io: IO, tokenItem: TokenItem, paymentMethodsInput: OnrampPaymentMethodsInput) {
        self.io = io
        self.tokenItem = tokenItem
        self.paymentMethodsInput = paymentMethodsInput
    }

    func makeOnrampProvidersViewModel(coordinator: any OnrampProvidersRoutable) -> ReturnValue {
        let interactor = makeOnrampProvidersInteractor(io: io)
        let viewModel = OnrampProvidersViewModel(tokenItem: tokenItem, interactor: interactor, coordinator: coordinator)

        return viewModel
    }

    func makeOnrampProvidersCompactViewModel() -> OnrampProvidersCompactViewModel {
        OnrampProvidersCompactViewModel(providersInput: io.input)
    }
}

// MARK: - Private

private extension OnrampProvidersBuilder {
    func makeOnrampProvidersInteractor(io: IO) -> OnrampProvidersInteractor {
        CommonOnrampProvidersInteractor(
            input: io.input,
            output: io.output,
            paymentMethodsInput: paymentMethodsInput
        )
    }
}
