//
//  CommonOnrampRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

class CommonOnrampRepository {
    private let storage: OnrampStorage
    private let preference: CurrentValueSubject<OnrampUserPreference, Never>

    init(storage: OnrampStorage) {
        self.storage = storage

        storage.save(preference: .init())
        preference = .init(storage.preference() ?? .init())
    }
}

// MARK: - OnrampRepository

extension CommonOnrampRepository: OnrampRepository {
    var savedCountry: OnrampCountry? {
        preference.value.country.map { country in
            mapToOnrampCountry(country: country)
        }
    }

    var savedPaymentMethod: OnrampPaymentMethod? {
        preference.value.paymentMethod.map { paymentMethod in
            mapToOnrampPaymentMethod(paymentMethod: paymentMethod)
        }
    }

    var savedCurrency: OnrampFiatCurrency? {
        preference.value.currency.map { currency in
            mapToOnrampFiatCurrency(currency: currency)
        }
    }

    func updatePreference(country: OnrampCountry) {
        preference.value.country = mapToOnrampUserPreferenceCountry(country: country)
    }

    func updatePreference(currency: OnrampFiatCurrency) {
        preference.value.currency = mapToOnrampUserPreferenceCurrency(currency: currency)
    }

    func updatePreference(paymentMethod: OnrampPaymentMethod) {
        preference.value.paymentMethod = mapToOnrampUserPreferencePaymentMethod(paymentMethod: paymentMethod)
    }

    var preferenceDidChangedPublisher: AnyPublisher<Void, Never> {
        preference.map { _ in () }.eraseToAnyPublisher()
    }

    func saveChanges() {
        storage.save(preference: preference.value)
    }
}

// MARK: - Mapping

private extension CommonOnrampRepository {
    func mapToOnrampCountry(country: OnrampUserPreference.Country) -> OnrampCountry {
        OnrampCountry(
            identity: .init(name: country.name, code: country.code, image: country.image),
            currency: mapToOnrampFiatCurrency(currency: country.currency),
            onrampAvailable: country.onrampAvailable
        )
    }

    func mapToOnrampFiatCurrency(currency: OnrampUserPreference.Currency) -> OnrampFiatCurrency {
        OnrampFiatCurrency(
            identity: .init(name: currency.name, code: currency.code, image: currency.image),
            precision: currency.precision
        )
    }

    func mapToOnrampPaymentMethod(paymentMethod: OnrampUserPreference.PaymentMethod) -> OnrampPaymentMethod {
        OnrampPaymentMethod(
            identity: .init(name: paymentMethod.name, code: paymentMethod.id, image: paymentMethod.image)
        )
    }

    func mapToOnrampUserPreferenceCountry(country: OnrampCountry) -> OnrampUserPreference.Country {
        OnrampUserPreference.Country(
            name: country.identity.name,
            code: country.identity.code,
            image: country.identity.image,
            currency: mapToOnrampUserPreferenceCurrency(currency: country.currency),
            onrampAvailable: country.onrampAvailable
        )
    }

    func mapToOnrampUserPreferenceCurrency(currency: OnrampFiatCurrency) -> OnrampUserPreference.Currency {
        OnrampUserPreference.Currency(
            name: currency.identity.name,
            code: currency.identity.code,
            image: currency.identity.image,
            precision: currency.precision
        )
    }

    func mapToOnrampUserPreferencePaymentMethod(paymentMethod: OnrampPaymentMethod) -> OnrampUserPreference.PaymentMethod {
        OnrampUserPreference.PaymentMethod(
            name: paymentMethod.identity.name,
            id: paymentMethod.identity.code,
            image: paymentMethod.identity.image
        )
    }
}
