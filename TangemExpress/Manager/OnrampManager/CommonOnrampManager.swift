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

    private var _providers: ProvidersList = [:]
    private var _selectedProvider: OnrampProvider?

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
    public var providers: ProvidersList { _providers }

    public var selectedProvider: OnrampProvider? { _selectedProvider }

    public func initialSetupCountry() async throws -> OnrampCountry {
        let country = try await apiProvider.onrampCountryByIP()
        return country
    }

    public func initialSetupPaymentMethod() async throws -> OnrampPaymentMethod {
        let paymentMethodDeterminer = PaymentMethodDeterminer(dataRepository: dataRepository)
        let method = try await paymentMethodDeterminer.preferredPaymentMethod()
        return method
    }

    public func setupProviders(request item: OnrampPairRequestItem) async throws {
        let pairs = try await apiProvider.onrampPairs(
            from: item.fiatCurrency,
            to: [item.destination.expressCurrency],
            country: item.country
        )

        let supportedProviders = pairs.flatMap { $0.providers }
        guard !supportedProviders.isEmpty else {
            // Exclude unnecessary requests
            return
        }

        // Fill the `_providers` with all possible options
        _providers = try await prepareProviders(item: item, supportedProviders: supportedProviders)
    }

    public func setupQuotes(amount: Decimal?) async throws {
        if _providers.isEmpty {
            throw OnrampManagerError.providersIsEmpty
        }

        await updateQuotesInEachManager(amount: amount)

        let paymentMethodDeterminer = PaymentMethodDeterminer(dataRepository: dataRepository)
        let paymentMethod = try await paymentMethodDeterminer.preferredPaymentMethod()

        try updateSelectedProvider(paymentMethod: paymentMethod)
    }

    public func updatePaymentMethod(paymentMethod: OnrampPaymentMethod) throws {
        try updateSelectedProvider(paymentMethod: paymentMethod)
    }

    public func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData {
        let item = try provider.manager.makeOnrampQuotesRequestItem()
        let requestItem = OnrampRedirectDataRequestItem(quotesItem: item, redirectSettings: redirectSettings)
        let data = try await apiProvider.onrampData(item: requestItem)

        return data
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func updateQuotesInEachManager(amount: Decimal?) async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            await self?._providers.values.flatMap { $0 }.forEach { provider in
                _ = group.addTaskUnlessCancelled {
                    try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
                    await provider.manager.update(amount: amount)
                }
            }

            await group.waitForAll()
        }
    }

    func updateSelectedProvider(paymentMethod: OnrampPaymentMethod) throws {
        guard let providers = _providers[paymentMethod] else {
            throw OnrampManagerError.noProviderForPaymentMethod
        }

        let sortedProviders = providers
            .sorted(by: { sort(lhs: $0.manager.state, rhs: $1.manager.state) })

        _selectedProvider = sortedProviders.first
    }

    func prepareProviders(
        item: OnrampPairRequestItem,
        supportedProviders: [OnrampPair.Provider]
    ) async throws -> ProvidersList {
        let providers = try await dataRepository.providers()
        let paymentMethods = try await dataRepository.paymentMethods()

        let supportedPaymentMethods = supportedProviders
            .flatMap { $0.paymentMethods }
            .compactMap { paymentMethodId in
                paymentMethods.first(where: { $0.id == paymentMethodId })
            }

        let availableProviders: ProvidersList = supportedPaymentMethods.reduce(into: [:]) { result, paymentMethod in
            result[paymentMethod] = providers.map { provider in
                let manager = CommonOnrampProviderManager(
                    pairItem: item,
                    expressProviderId: provider.id,
                    paymentMethodId: paymentMethod.id,
                    apiProvider: apiProvider,
                    state: state(provider: provider, paymentMethod: paymentMethod)
                )

                return OnrampProvider(
                    provider: provider,
                    paymentMethod: paymentMethod,
                    manager: manager
                )
            }
        }

        func state(provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) -> OnrampProviderManagerState {
            guard let supportedProvider = supportedProviders.first(where: { $0.id == provider.id }) else {
                return .notSupported(.currentPair)
            }

            let isSupportedForPaymentMethods = supportedProvider.paymentMethods.contains { $0 == paymentMethod.id }
            guard isSupportedForPaymentMethods else {
                return .notSupported(.paymentMethod)
            }

            return .idle
        }

        return availableProviders
    }

    func sort(lhs: OnrampProviderManagerState, rhs: OnrampProviderManagerState) -> Bool {
        switch (lhs, rhs) {
        case (_, .restriction):
            return true
        case (.restriction, _):
            return false
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)):
            return lhsQuote.expectedAmount > rhsQuote.expectedAmount
        default:
            return false
        }
    }
}
