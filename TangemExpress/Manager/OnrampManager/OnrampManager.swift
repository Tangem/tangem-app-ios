//
//  OnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampManager: Actor {
    /// Initial loading country by IP
    /// If the country has already been setup then return nil
    func initialSetupCountry() async throws -> OnrampCountry

    /// User has selected a currency. We are preparing onramp providers
    func setupProviders(request: OnrampPairRequestItem) async throws -> [OnrampAvailableProvider]

    /// The user changed the amount. We upload providers quotes
    func setupQuotes(amount: Decimal) async throws -> [OnrampAvailableProvider]

    /// Load the data to perform the onramp action
    func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData
}

public enum OnrampManagerError: LocalizedError {
    case notImplement
}
