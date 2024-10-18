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
    let provider: ExpressAPIProvider

    init(provider: ExpressAPIProvider) {
        self.provider = provider
    }
}

// MARK: - OnrampRepository

// TODO: https://tangem.atlassian.net/browse/IOS-8268
// Add method to save values which user chose
extension CommonOnrampRepository: OnrampRepository {
    var savedCountry: OnrampCountry? { nil }
    var savedPaymentMethod: OnrampPaymentMethod? { nil }
    var savedCountryPublisher: AnyPublisher<OnrampCountry?, Never> { Empty().eraseToAnyPublisher() }

    func save(country: OnrampCountry) throws {}

    func save(paymentMethod: OnrampPaymentMethod) throws {}
}
