//
//  OnrampInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampInteractor: AnyObject {
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
    var selectedOnrampValues: AnyPublisher<(OnrampAvailableProvider, OnrampPaymentMethod), Never> { get }
}

class CommonOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?

    private let _isValid: CurrentValueSubject<Bool, Never> = .init(true)

    init(
        input: OnrampInput,
        output: OnrampOutput,
        providersInput: OnrampProvidersInput,
        paymentMethodsInput: OnrampPaymentMethodsInput
    ) {
        self.input = input
        self.output = output
        self.providersInput = providersInput
        self.paymentMethodsInput = paymentMethodsInput
    }
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var isValidPublisher: AnyPublisher<Bool, Never> {
        _isValid.eraseToAnyPublisher()
    }

    var selectedOnrampValues: AnyPublisher<(OnrampAvailableProvider, OnrampPaymentMethod), Never> {
        guard let providersInput, let paymentMethodsInput else {
            assertionFailure("OnrampProvidersInput, OnrampPaymentMethodsInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            providersInput.selectedOnrampProviderPublisher.compactMap { $0 },
            paymentMethodsInput.selectedOnrampPaymentMethodPublisher.compactMap { $0 }
        )
        .map { provider, paymentMethod in
            (provider, paymentMethod)
        }
        .eraseToAnyPublisher()
    }
}
