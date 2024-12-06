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

    var preferencePublisher: AnyPublisher<OnrampPreference, Never> {
        preference.map { [weak self] preference in
            let country = preference.country.flatMap { country in
                self?.mapToOnrampCountry(country: country)
            }

            let currency = preference.currency.flatMap { currency in
                self?.mapToOnrampFiatCurrency(currency: currency)
            }

            return OnrampPreference(country: country, currency: currency)
        }
        .eraseToAnyPublisher()
    }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?) {
        var newPreference = preference.value

        if let country {
            newPreference.country = mapToOnrampUserPreferenceCountry(country: country)
        }

        if let currency {
            newPreference.currency = mapToOnrampUserPreferenceCurrency(currency: currency)
        }

        lockQueue.sync {
            storage.save(preference: newPreference)
        }

        preference.send(newPreference)
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
}
