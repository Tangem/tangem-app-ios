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
    private let lockQueue = DispatchQueue(label: "com.tangem.OnrampRepository.lockQueue")

    init(storage: OnrampStorage) {
        self.storage = storage

        preference = .init(storage.preference() ?? .init())
    }
}

// MARK: - OnrampRepository

extension CommonOnrampRepository: OnrampRepository {
    var preferenceCountry: OnrampCountry? {
        preference.value.country.map(mapToOnrampCountry)
    }

    var preferenceCurrency: OnrampFiatCurrency? {
        preference.value.currency.map(mapToOnrampFiatCurrency)
    }

    var preferencePaymentMethod: OnrampPaymentMethod? {
        preference.value.paymentMethod.map(mapToOnrampPaymentMethod)
    }

    var preferenceCountryPublisher: AnyPublisher<OnrampCountry?, Never> {
        preference.map { [weak self] preference in
            preference.country.flatMap { country in
                self?.mapToOnrampCountry(country: country)
            }
        }
        .eraseToAnyPublisher()
    }

    var preferenceCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        preference.map { [weak self] preference in
            preference.currency.flatMap { currency in
                self?.mapToOnrampFiatCurrency(currency: currency)
            }
        }
        .eraseToAnyPublisher()
    }

    var preferencePaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> {
        preference.map { [weak self] preference in
            preference.paymentMethod.flatMap { paymentMethod in
                self?.mapToOnrampPaymentMethod(paymentMethod: paymentMethod)
            }
        }
        .eraseToAnyPublisher()
    }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?, paymentMethod: OnrampPaymentMethod?) {
        var newPreference = preference.value

        if let country {
            newPreference.country = mapToOnrampUserPreferenceCountry(country: country)
        }

        if let currency {
            newPreference.currency = mapToOnrampUserPreferenceCurrency(currency: currency)
        }

        if let paymentMethod {
            newPreference.paymentMethod = mapToOnrampUserPreferencePaymentMethod(paymentMethod: paymentMethod)
        }

        lockQueue.sync {
            storage.save(preference: newPreference)
        }

        preference.send(newPreference)
    }

    var preferenceDidChangedPublisher: AnyPublisher<Void, Never> {
        preference.map { _ in () }.eraseToAnyPublisher()
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
            id: paymentMethod.id,
            name: paymentMethod.name,
            image: paymentMethod.image
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
            name: paymentMethod.name,
            id: paymentMethod.id,
            image: paymentMethod.image
        )
    }
}
