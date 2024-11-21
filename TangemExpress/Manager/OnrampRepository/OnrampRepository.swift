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

    var preferenceCountryPublisher: AnyPublisher<OnrampCountry?, Never> { get }
    var preferenceCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?)
}

public extension OnrampRepository {
    func updatePreference(country: OnrampCountry? = nil, currency: OnrampFiatCurrency? = nil) {
        updatePreference(country: country, currency: currency)
    }

    var preferencePublisher: AnyPublisher<OnrampPreference, Never> {
        Publishers.CombineLatest(preferenceCountryPublisher, preferenceCurrencyPublisher)
            .map { OnrampPreference(country: $0, currency: $1) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

public struct OnrampPreference: Hashable {
    public let country: OnrampCountry?
    public let currency: OnrampFiatCurrency?
}
