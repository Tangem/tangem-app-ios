//
//  OnrampRedirectingBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampRedirectingBuilder {
    typealias IO = (input: OnrampRedirectingInput, output: OnrampRedirectingOutput)
    typealias ReturnValue = OnrampRedirectingViewModel

    private let io: IO
    private let tokenItem: TokenItem
    private let onrampManager: OnrampManager

    init(io: IO, tokenItem: TokenItem, onrampManager: OnrampManager) {
        self.io = io
        self.tokenItem = tokenItem
        self.onrampManager = onrampManager
    }

    func makeOnrampRedirectingViewModel(coordinator: some OnrampRedirectingRoutable) -> ReturnValue {
        let interactor = makeOnrampPaymentMethodsInteractor()
        let viewModel = OnrampRedirectingViewModel(tokenItem: tokenItem, interactor: interactor, coordinator: coordinator)

        return viewModel
    }
}

// MARK: - Private

private extension OnrampRedirectingBuilder {
    func makeOnrampPaymentMethodsInteractor() -> OnrampRedirectingInteractor {
        CommonOnrampRedirectingInteractor(
            input: io.input,
            output: io.output,
            onrampManager: onrampManager
        )
    }
}
