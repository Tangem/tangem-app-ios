//
//  OnrampRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public protocol OnrampRepository {
    var preferenceCountry: OnrampCountry? { get }
    var preferenceCurrency: OnrampFiatCurrency? { get }
    var preferencePaymentMethod: OnrampPaymentMethod? { get }

    var preferenceCountryPublisher: AnyPublisher<OnrampCountry?, Never> { get }
    var preferenceCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }
    var preferencePaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> { get }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?, paymentMethod: OnrampPaymentMethod?)
}

public extension OnrampRepository {
    func updatePreference(country: OnrampCountry? = nil, currency: OnrampFiatCurrency? = nil, paymentMethod: OnrampPaymentMethod? = nil) {
        updatePreference(country: country, currency: currency, paymentMethod: paymentMethod)
    }
}
