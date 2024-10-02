//
//  OnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampManager {
    func getCountry() async throws -> OnrampCountry
    func getCountries() async throws -> [OnrampCountry]
    func getPaymentMethods() async throws -> [OnrampCountry]

    func loadProviders(pair: OnrampPair) async throws -> [OnrampProvider]
    func loadQuotes(pair: OnrampPair, amount: Decimal) async throws -> [OnrampQuote]
}

public struct OnrampQuote: Hashable {}

public struct OnrampPaymentMethod {}

public struct OnrampProvider {}
