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
    var expectedTokenAmountPublisher: AnyPublisher<LoadingResult<Decimal?, Never>?, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }

    func update(fiat: Decimal?)
}

class CommonOnrampAmountInteractor {
    private weak var input: OnrampAmountInput?
    private weak var output: OnrampAmountOutput?
    private weak var onrampProvidersInput: OnrampProvidersInput?

    private var _error: CurrentValueSubject<String?, Never> = .init(nil)
    private var bag: Set<AnyCancellable> = []

    init(
        input: OnrampAmountInput,
        output: OnrampAmountOutput,
        onrampProvidersInput: OnrampProvidersInput
    ) {
        self.input = input
        self.output = output
        self.onrampProvidersInput = onrampProvidersInput

        bind(onrampProvidersInput: onrampProvidersInput)
    }
}

// MARK: - Private

private extension CommonOnrampAmountInteractor {
    func bind(onrampProvidersInput: OnrampProvidersInput) {
        Publishers.CombineLatest(
            onrampProvidersInput.onrampProvidersPublisher,
            onrampProvidersInput.selectedOnrampProviderPublisher
        ).map { providers, provider in
            switch (providers, provider?.value?.state) {
            case (.success(let providers), _) where !providers.hasProviders():
                return Localization.onrampNoAvailableProviders
            case (_, .restriction(.tooSmallAmount(let minAmount))):
                return Localization.onrampMinAmountRestriction(minAmount)
            case (_, .restriction(.tooBigAmount(let maxAmount))):
                return Localization.onrampMaxAmountRestriction(maxAmount)
            default:
                return nil
            }
        }
        .assign(to: \._error.value, on: self, ownership: .weak)
        .store(in: &bag)
    }
}

// MARK: - OnrampAmountInteractor

extension CommonOnrampAmountInteractor: OnrampAmountInteractor {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        guard let input else {
            assertionFailure("OnrampAmountInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.fiatCurrencyPublisher.map { $0.value }.eraseToAnyPublisher()
    }

    var expectedTokenAmountPublisher: AnyPublisher<LoadingResult<Decimal?, Never>?, Never> {
        guard let onrampProvidersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return onrampProvidersInput
            .selectedOnrampProviderPublisher
            .withWeakCaptureOf(self)
            .map { interactor, provider in
                provider?.mapValue { provider in
                    switch provider.state {
                    case .idle: 0 // Placeholder
                    case .loaded(let quote): quote.expectedAmount
                    case .restriction, .failed, .loading, .notSupported: nil
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String?, Never> {
        _error.eraseToAnyPublisher()
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
