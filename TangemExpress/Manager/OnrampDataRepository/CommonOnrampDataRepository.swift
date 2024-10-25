//
//  CommonOnrampDataRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public class CommonOnrampDataRepository {
    private let provider: ExpressAPIProvider

    private var _paymentMethods: [OnrampPaymentMethod]?
    private var _countries: [OnrampCountry]?
    private var _currencies: [OnrampFiatCurrency]?

    init(provider: ExpressAPIProvider) {
        self.provider = provider
    }
}

// MARK: - OnrampDataRepository

extension CommonOnrampDataRepository: OnrampDataRepository {
    public func paymentMethods() async throws -> [OnrampPaymentMethod] {
        if let paymentMethods = _paymentMethods {
            return paymentMethods
        }

        let paymentMethods = try await provider.onrampPaymentMethods()
        _paymentMethods = paymentMethods

        return paymentMethods
    }

    public func countries() async throws -> [OnrampCountry] {
        if let countries = _countries {
            return countries
        }

        let countries = try await provider.onrampCountries()
        _countries = countries

        return countries
    }

    public func currencies() async throws -> [OnrampFiatCurrency] {
        if let currencies = _currencies {
            return currencies
        }

        let currencies = try await provider.onrampCurrencies()
        _currencies = currencies

        return currencies
    }
}
