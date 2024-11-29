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
    func setupProviders(request: OnrampPairRequestItem) async throws -> ProvidersList

    /// The user changed the amount. We upload providers quotes
    func setupQuotes(in providers: ProvidersList, amount: Decimal?) async throws -> OnrampProvider

    /// Reload quote in the provider
    func setupQuotes(in provider: OnrampProvider) async -> OnrampProvider

    /// Reselect `paymentMethod` and sort providers according to it
    func suggestProvider(in providers: ProvidersList, paymentMethod: OnrampPaymentMethod) throws -> OnrampProvider

    /// Load the data to perform the onramp action
    func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData
}

public enum OnrampManagerError: LocalizedError {
    case noProviderForPaymentMethod
    case providersIsEmpty
    case suggestedProviderNotFound

    public var errorDescription: String? {
        switch self {
        case .noProviderForPaymentMethod: "No provider for payment method"
        case .providersIsEmpty: "Providers is empty"
        case .suggestedProviderNotFound: "Suggested provider not found"
        }
    }
}
