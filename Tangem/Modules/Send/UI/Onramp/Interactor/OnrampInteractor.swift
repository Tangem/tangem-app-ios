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
    var selectedProviderPublisher: AnyPublisher<ExpressProvider?, Never> { get }

    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
}

class CommonOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?
    private weak var providersInput: OnrampProvidersInput?

    init(
        input: OnrampInput,
        output: OnrampOutput,
        providersInput: OnrampProvidersInput
    ) {
        self.input = input
        self.output = output
        self.providersInput = providersInput
    }
}

// MARK: - OnrampInteractor

extension CommonOnrampInteractor: OnrampInteractor {
    var selectedProviderPublisher: AnyPublisher<ExpressProvider?, Never> {
        guard let providersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return providersInput
            .selectedOnrampProviderPublisher
            .map { $0?.value?.provider }
            .eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("OnrampInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isValidToRedirectPublisher
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        guard let providersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            providersInput.selectedOnrampProviderPublisher.map { $0?.isLoading ?? false },
            providersInput.onrampProvidersPublisher.map { $0?.isLoading ?? false }
        )
        .map { $0 || $1 }
        .eraseToAnyPublisher()
    }
}
