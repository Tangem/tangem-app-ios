//
//  OnrampRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public protocol OnrampRepository {
    var savedCountry: OnrampCountry? { get }
    var savedCurrency: OnrampFiatCurrency? { get }
    var savedPaymentMethod: OnrampPaymentMethod? { get }

    var preferenceDidChangedPublisher: AnyPublisher<Void, Never> { get }

    func updatePreference(country: OnrampCountry)
    func updatePreference(currency: OnrampFiatCurrency)
    func updatePreference(paymentMethod: OnrampPaymentMethod)

    func saveChanges()
}
