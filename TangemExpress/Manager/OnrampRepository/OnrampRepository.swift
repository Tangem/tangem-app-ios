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
    var preferencePublisher: AnyPublisher<OnrampPreference, Never> { get }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?)
}

public extension OnrampRepository {
    func updatePreference(country: OnrampCountry? = nil, currency: OnrampFiatCurrency? = nil) {
        updatePreference(country: country, currency: currency)
    }
}
