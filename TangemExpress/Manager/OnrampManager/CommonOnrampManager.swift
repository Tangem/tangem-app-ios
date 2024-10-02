//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

// For every onramp provider
protocol OnrampProviderManager: Actor {
    func state() -> OnrampProviderManagerState
}

enum OnrampProviderManagerState: Hashable {
    case loading
    case failed(String)
    case loaded(quote: OnrampQuote)
}

struct CommonOnrampManager {
    private let provider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
}

// MARK: - OnrampManager

extension CommonOnrampManager: OnrampManager {
    func getCountry() async throws -> OnrampCountry {
        // TODO: Define country by ip
        //
    }

    func getCountries() async throws -> [OnrampCountry] {
        // TODO: Load all countries
        // Or get it from repository (?)
    }

    func getPaymentMethods() async throws -> [OnrampCountry] {
        // TODO: Load payment methods
        // Or get it from repository (?)
    }

    func loadProviders(pair: OnrampPair) async throws -> [OnrampProvider] {
        <#code#>
    }

    func loadQuotes(pair: OnrampPair, amount: Decimal) async throws -> [OnrampQuote] {}
}
