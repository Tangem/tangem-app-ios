//
//  OnrampPaymentMethodsInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampPaymentMethodsInteractor {
    var paymentMethodPublisher: AnyPublisher<OnrampPaymentMethod, Never> { get }
    var paymentMethods: AnyPublisher<[OnrampPaymentMethod], Never> { get }

    func update(selectedPaymentMethod: OnrampPaymentMethod)
}

class CommonOnrampPaymentMethodsInteractor {
    private weak var input: OnrampPaymentMethodsInput?
    private weak var output: OnrampPaymentMethodsOutput?
    private let dataRepository: OnrampDataRepository

    init(
        input: OnrampPaymentMethodsInput,
        output: OnrampPaymentMethodsOutput,
        dataRepository: OnrampDataRepository
    ) {
        self.input = input
        self.output = output
        self.dataRepository = dataRepository
    }
}

// MARK: - OnrampProvidersInteractor

extension CommonOnrampPaymentMethodsInteractor: OnrampPaymentMethodsInteractor {
    var paymentMethodPublisher: AnyPublisher<OnrampPaymentMethod, Never> {
        guard let input else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .selectedOnrampPaymentMethodPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var paymentMethods: AnyPublisher<[OnrampPaymentMethod], Never> {
        Future.async {
            try await self.dataRepository.paymentMethods()
        }
        .replaceError(with: [])
        .eraseToAnyPublisher()
    }

    func update(selectedPaymentMethod: OnrampPaymentMethod) {
        output?.userDidSelect(paymentMethod: selectedPaymentMethod)
    }
}
