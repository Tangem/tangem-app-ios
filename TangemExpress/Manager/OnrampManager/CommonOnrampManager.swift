//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public actor CommonOnrampManager {
    private let apiProvider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private let logger: Logger

//    private var _providers: ProvidersList = []

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

    public func setupProviders(request item: OnrampPairRequestItem) async throws -> ProvidersList {
        let pairs = try await apiProvider.onrampPairs(
            from: item.fiatCurrency,
            to: [item.destination.expressCurrency],
            country: item.country
        )

        let supportedProviders = pairs.flatMap { $0.providers }
        log(message: "Load pairs with supported providers \(supportedProviders)")
        guard !supportedProviders.isEmpty else {
            // Exclude unnecessary requests
            return []
        }

        // Fill the `_providers` with all possible options
        let providers = try await prepareProviders(item: item, supportedProviders: supportedProviders)
        return providers
    }

    public func setupQuotes(in providers: ProvidersList, amount: Decimal?) async throws -> OnrampProvider {
        log(message: "Start update quotes")
        try await updateQuotesInEachManager(providers: providers, amount: amount)
        log(message: "The quotes was updated")

        return try proceedProviders(providers: providers)
    }

    public func suggestProvider(in providers: ProvidersList, paymentMethod: OnrampPaymentMethod) throws -> OnrampProvider {
        log(message: "Payment method was updated by user to: \(paymentMethod)")

        let providerItem = providers.select(for: paymentMethod)
        let best = providerItem?.updateBest()
        log(message: "The best provider was define to \(best as Any)")

        guard let selectedProvider = providerItem?.suggestProvider() else {
            throw OnrampManagerError.noProviderForPaymentMethod
        }

        log(message: "New selected provider was updated to: \(selectedProvider as Any)")
        return selectedProvider
    }

    public func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData {
        let item = try provider.makeOnrampQuotesRequestItem()
        let requestItem = OnrampRedirectDataRequestItem(quotesItem: item, redirectSettings: redirectSettings)
        let data = try await apiProvider.onrampData(item: requestItem)

        return data
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func updateQuotesInEachManager(providers: ProvidersList, amount: Decimal?) async throws {
        if providers.isEmpty {
            throw OnrampManagerError.providersIsEmpty
        }

        await withTaskGroup(of: Void.self) { [weak self] group in
            providers.flatMap { $0.providers }.forEach { provider in
                _ = group.addTaskUnlessCancelled {
                    await provider.update(amount: amount)
                    await self?.log(message: "Quotes was loaded in: \(provider)")
                }
            }
        }
    }

    func proceedProviders(providers: ProvidersList) throws -> OnrampProvider {
        log(message: "Start to find the best provider")

        for provider in providers {
            let sorted = provider.sort()
            log(message: "Providers for paymentMethod: \(provider.paymentMethod.name) was sorted to order: \(sorted)")

            let best = provider.updateBest()
            log(message: "The best provider was defined to \(best as Any)")

            if let maxPriorityProvider = provider.suggestProvider() {
                log(message: "The suggested provider is \(maxPriorityProvider)")
                return maxPriorityProvider
            }
        }

        log(message: "We couldn't find any provider without error")
        guard let suggestProvider = providers.first?.providers.first else {
            throw OnrampManagerError.suggestedProviderNotFound
        }

        log(message: "Then update selected provider to \(suggestProvider as Any)")
        return suggestProvider
    }

    func prepareProviders(item: OnrampPairRequestItem, supportedProviders: [OnrampPair.Provider]) async throws -> ProvidersList {
        let providers = try await dataRepository.providers()
        let paymentMethods = try await dataRepository.paymentMethods()

        let supportedPaymentMethods = supportedProviders
            .flatMap { $0.paymentMethods }
            .compactMap { paymentMethodId in
                paymentMethods.first(where: { $0.id == paymentMethodId })
            }
            // Sort payment methods to order which will suggest to user
            .sorted(by: { $0.type.priority > $1.type.priority })

        let availableProviders: ProvidersList = supportedPaymentMethods.map { paymentMethod in
            let providers = providers.map { provider in
                OnrampProvider(
                    provider: provider,
                    paymentMethod: paymentMethod,
                    manager: makeOnrampProviderManager(
                        item: item,
                        provider: provider,
                        paymentMethod: paymentMethod,
                        supportedProviders: supportedProviders
                    )
                )
            }

            return ProviderItem(paymentMethod: paymentMethod, providers: providers)
        }

        log(message: "Built providers \(availableProviders)")

        return availableProviders
    }

    func makeOnrampProviderManager(
        item: OnrampPairRequestItem,
        provider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        supportedProviders: [OnrampPair.Provider]
    ) -> OnrampProviderManager {
        let state: OnrampProviderManagerState = {
            guard let supportedProvider = supportedProviders.first(where: { $0.id == provider.id }) else {
                return .notSupported(.currentPair)
            }

            let isSupportedForPaymentMethods = supportedProvider.paymentMethods.contains { $0 == paymentMethod.id }
            guard isSupportedForPaymentMethods else {
                return .notSupported(.paymentMethod)
            }

            return .idle
        }()

        return CommonOnrampProviderManager(
            pairItem: item,
            expressProviderId: provider.id,
            paymentMethodId: paymentMethod.id,
            apiProvider: apiProvider,
            state: state
        )
    }

    func log(message: String) {
        logger.debug("[\(TangemFoundation.objectDescription(self))] \(message)")
    }
}
