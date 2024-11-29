//
//  OnrampProvidersInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampProvidersInteractor {
    var paymentMethodPublisher: AnyPublisher<OnrampPaymentMethod, Never> { get }

    var selectedProviderPublisher: AnyPublisher<OnrampProvider?, Never> { get }
    var providesPublisher: AnyPublisher<[OnrampProvider], Never> { get }

    func update(selectedProvider: OnrampProvider)
}

class CommonOnrampProvidersInteractor {
    private weak var input: OnrampProvidersInput?
    private weak var output: OnrampProvidersOutput?
    private weak var paymentMethodsInput: OnrampPaymentMethodsInput?

    init(
        input: OnrampProvidersInput,
        output: OnrampProvidersOutput,
        paymentMethodsInput: OnrampPaymentMethodsInput
    ) {
        self.input = input
        self.output = output
        self.paymentMethodsInput = paymentMethodsInput
    }
}

// MARK: - OnrampProvidersInteractor

extension CommonOnrampProvidersInteractor: OnrampProvidersInteractor {
    var paymentMethodPublisher: AnyPublisher<OnrampPaymentMethod, Never> {
        guard let input = paymentMethodsInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .selectedPaymentMethodPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var selectedProviderPublisher: AnyPublisher<OnrampProvider?, Never> {
        guard let input else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .selectedOnrampProviderPublisher
            .map { $0?.value }
            .eraseToAnyPublisher()
    }

    var providesPublisher: AnyPublisher<[OnrampProvider], Never> {
        guard let input else {
            assertionFailure("OnrampAmountInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers
            .CombineLatest(input.onrampProvidersPublisher, paymentMethodPublisher)
            .compactMap { $0?.value?.select(for: $1)?.providers }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func update(selectedProvider: OnrampProvider) {
        output?.userDidSelect(provider: selectedProvider)
    }
}
