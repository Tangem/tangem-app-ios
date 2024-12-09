//
//  OnrampAmountInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 30.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol OnrampAmountInteractor {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }
    var bottomInfoPublisher: AnyPublisher<LoadingResult<Decimal, OnrampAmountInteractorBottomInfoError>?, Never> { get }

    func update(fiat: Decimal?)
}

enum OnrampAmountInteractorBottomInfoError: Error {
    case noAvailableProviders
    case tooSmallAmount(_ minAmount: String)
    case tooBigAmount(_ maxAmount: String)
}

class CommonOnrampAmountInteractor {
    private weak var input: OnrampAmountInput?
    private weak var output: OnrampAmountOutput?
    private weak var onrampProvidersInput: OnrampProvidersInput?

    init(
        input: OnrampAmountInput,
        output: OnrampAmountOutput,
        onrampProvidersInput: OnrampProvidersInput
    ) {
        self.input = input
        self.output = output
        self.onrampProvidersInput = onrampProvidersInput
    }
}

// MARK: - OnrampAmountInteractor

extension CommonOnrampAmountInteractor: OnrampAmountInteractor {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        guard let input else {
            assertionFailure("OnrampAmountInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.fiatCurrencyPublisher.eraseToAnyPublisher()
    }

    var bottomInfoPublisher: AnyPublisher<LoadingResult<Decimal, OnrampAmountInteractorBottomInfoError>?, Never> {
        guard let onrampProvidersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        let hasProviders = onrampProvidersInput
            .onrampProvidersPublisher
            .map { providers in
                switch providers {
                case .none, .loading, .failure:
                    return false
                case .success(let providers):
                    return !providers.hasProviders()
                }
            }

        return Publishers
            .CombineLatest(hasProviders, onrampProvidersInput.selectedOnrampProviderPublisher)
            .map { hasProviders, provider -> LoadingResult<Decimal, OnrampAmountInteractorBottomInfoError>? in
                guard !hasProviders else {
                    return .failure(.noAvailableProviders)
                }

                switch (provider, provider?.value?.state) {
                case (_, .restriction(.tooSmallAmount(let minAmount))):
                    return .failure(.tooSmallAmount(minAmount))
                case (_, .restriction(.tooBigAmount(let maxAmount))):
                    return .failure(.tooSmallAmount(maxAmount))
                case (.none, _), (_, .idle):
                    return .success(0) // placeholder
                case (.loading, _), (_, .loading):
                    return .loading
                case (_, .loaded(let quote)):
                    return .success(quote.expectedAmount)
                case (_, .failed), (_, .notSupported), (_, .none):
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    func update(fiat: Decimal?) {
        guard let fiat, fiat > 0 else {
            // Field is empty or zero
            output?.amountDidChanged(fiat: .none)
            return
        }

        output?.amountDidChanged(fiat: fiat)
    }
}
