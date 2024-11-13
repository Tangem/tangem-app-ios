//
//  OnrampAmountInteractor.swift
//  TangemApp
//
//  Created by Sergey Balashov on 30.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampAmountInteractor {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }

    func update(amount: Decimal?) async -> SendAmount?
}

class CommonOnrampAmountInteractor {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private weak var input: OnrampAmountInput?
    private weak var output: OnrampAmountOutput?
    private weak var onrampProvidersInput: OnrampProvidersInput?
    private let tokenItem: TokenItem

    private var _error: CurrentValueSubject<String?, Never> = .init(nil)
    private var bag: Set<AnyCancellable> = []

    init(
        input: OnrampAmountInput,
        output: OnrampAmountOutput,
        onrampProvidersInput: OnrampProvidersInput,
        tokenItem: TokenItem
    ) {
        self.input = input
        self.output = output
        self.onrampProvidersInput = onrampProvidersInput
        self.tokenItem = tokenItem

        bind(onrampProvidersInput: onrampProvidersInput)
    }
}

// MARK: - Private

private extension CommonOnrampAmountInteractor {
    func bind(onrampProvidersInput: OnrampProvidersInput) {
        Publishers.CombineLatest(
            onrampProvidersInput.onrampProvidersPublisher,
            onrampProvidersInput.selectedOnrampProviderPublisher.map { $0?.value?.manager.state }
        ).map { providers, state in
            switch (providers, state) {
            case (.loaded(let providers), _) where providers.isEmpty:
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

    func makeSendAmount(fiat: Decimal) async -> SendAmount {
        guard let currency = input?.fiatCurrency.value,
              let currencyId = tokenItem.currencyId else {
            return .init(type: .alternative(fiat: fiat, crypto: nil))
        }

        let price = await quotesRepository.loadPrice(currencyCode: currency.identity.code, currencyId: currencyId)
        let crypto = price.map { fiat / $0 }

        return .init(type: .alternative(fiat: fiat, crypto: crypto))
    }

    private func validateAndUpdate(amount: SendAmount?) {
        guard let fiat = amount?.fiat, fiat > 0 else {
            // Field is empty or zero
            output?.amountDidChanged(amount: .none)
            return
        }

        output?.amountDidChanged(amount: amount)
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

    var errorPublisher: AnyPublisher<String?, Never> {
        _error.eraseToAnyPublisher()
    }

    func update(amount: Decimal?) async -> SendAmount? {
        guard let amount else {
            validateAndUpdate(amount: nil)
            return nil
        }

        let sendAmount = await makeSendAmount(fiat: amount)
        validateAndUpdate(amount: sendAmount)
        return sendAmount
    }
}
