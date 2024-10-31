//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public actor CommonOnrampManager {
    private let apiProvider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private let logger: Logger

    private var _providers: [OnrampProvider] = []

    public init(
        apiProvider: ExpressAPIProvider,
        onrampRepository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        logger: Logger
    ) {
        self.apiProvider = apiProvider
        self.onrampRepository = onrampRepository
        self.dataRepository = dataRepository
        self.logger = logger
    }
}

// MARK: - OnrampManager

extension CommonOnrampManager: OnrampManager {
    public func initialSetupCountry() async throws -> OnrampCountry {
        let country = try await apiProvider.onrampCountryByIP()
        return country
    }

    public func setupProviders(request: OnrampPairRequestItem) async throws -> [OnrampProvider] {
        let pairs = try await apiProvider.onrampPairs(
            from: item.fiatCurrency,
            to: [item.destination.expressCurrency],
            country: item.country
        )

        let supportedProviders = pairs.flatMap { $0.providers }
        guard !supportedProviders.isEmpty else {
            // Exclude unnecessary requests
            return []
        }

        // Fill the `_providers` with all possible options
        _providers = try await prepareProviders(item: item, supportedProviders: supportedProviders)

        return _providers
    }

    public func setupQuotes(amount: Decimal) async throws -> [OnrampProviderManager] {
        try await updateQuotesInEachManager(amount: amount)

        return _providers
    }

    public func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func updateQuotesInEachManager(amount: Decimal) async throws {
        await withTaskGroup(of: Void.self) { [weak self] group in
            await self?._providers.forEach { provider in
                _ = group.addTaskUnlessCancelled {
                    await provider.update(amount: amount)
                }
            }
        }
    }

    func prepareProviders(
        item: OnrampPairRequestItem,
        supportedProviders: [OnrampProvider]
    ) async throws -> [CommonOnrampProviderManager] {
        let providers = try await dataRepository.providers()
        let paymentMethods = try await dataRepository.paymentMethods()

        var availableProviders: [CommonOnrampProviderManager] = []

        for provider in providers {
            for paymentMethod in paymentMethods {
                availableProviders.append(CommonOnrampProviderManager(
                    pairItem: item,
                    provider: provider,
                    paymentMethod: paymentMethod,
                    apiProvider: apiProvider,
                    state: state(provider: provider, paymentMethod: paymentMethod)
                ))
            }
        }

        func state(provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) -> OnrampProviderManagerState {
            guard let supportedProvider = supportedProviders.first(where: { $0.id == provider.id }) else {
                return .notSupported(.currentPair)
            }

            let isSupportedForPaymentMethods = supportedProvider.paymentMethods.contains { $0 == paymentMethod.identity.code }
            guard isSupportedForPaymentMethods else {
                return .notSupported(.paymentMethod)
            }

            return .created
        }

        return availableProviders
    }
}
