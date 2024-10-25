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
    var currencyPublisher: AnyPublisher<LoadingValue<OnrampFiatCurrency>, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }

    func update(amount: Decimal?) async -> SendAmount?
}

class CommonOnrampAmountInteractor {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private weak var input: OnrampAmountInput?
    private weak var output: OnrampAmountOutput?
    private let tokenItem: TokenItem
    private let validator: SendAmountValidator

    private var _error: CurrentValueSubject<String?, Never> = .init(nil)
    private var _isValid: CurrentValueSubject<Bool, Never> = .init(false)

    init(
        input: OnrampAmountInput,
        output: OnrampAmountOutput,
        tokenItem: TokenItem,
        validator: SendAmountValidator
    ) {
        self.input = input
        self.output = output
        self.tokenItem = tokenItem
        self.validator = validator
    }
}

// MARK: - Private

private extension CommonOnrampAmountInteractor {
    func makeSendAmount(fiat: Decimal) async -> SendAmount {
        guard let currency = input?.fiatCurrency.value,
              let currencyId = tokenItem.currencyId else {
            return .init(type: .alternative(fiat: fiat, crypto: nil))
        }

        let price = await quotesRepository.loadPrice(currencyCode: currency.identity.code, currencyId: currencyId)
        let crypto = price.map { fiat * $0 }

        return .init(type: .alternative(fiat: fiat, crypto: crypto))
    }

    private func validateAndUpdate(amount: SendAmount?) {
        do {
            guard let crypto = amount?.crypto, crypto > 0 else {
                // Field is empty or zero
                update(amount: .none, isValid: false, error: .none)
                return
            }

            try validator.validate(amount: crypto)
            update(amount: amount, isValid: true, error: .none)
        } catch {
            update(amount: .none, isValid: false, error: error)
        }
    }

    private func update(amount: SendAmount?, isValid: Bool, error: Error?) {
        _error.send(error?.localizedDescription)
        _isValid.send(isValid)
        output?.amountDidChanged(amount: amount)
    }
}

// MARK: - OnrampAmountInteractor

extension CommonOnrampAmountInteractor: OnrampAmountInteractor {
    var currencyPublisher: AnyPublisher<LoadingValue<OnrampFiatCurrency>, Never> {
        guard let input else {
            assertionFailure("OnrampAmountInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.currencyPublisher.eraseToAnyPublisher()
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
        return sendAmount
    }
}
