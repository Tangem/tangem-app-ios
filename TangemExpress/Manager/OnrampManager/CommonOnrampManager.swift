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
            from: request.fiatCurrency,
            to: [request.destination.expressCurrency],
            country: request.country
        )

        // TODO: https://tangem.atlassian.net/browse/IOS-8310

        return _providers
    }

    public func setupQuotes(amount: Decimal) async throws -> [OnrampProvider] {
        /*
         TODO: https://tangem.atlassian.net/browse/IOS-8310
         await withTaskGroup(of: Void.self) { [weak self] group in
             await self?._providers.forEach { provider in
                 _ = group.addTaskUnlessCancelled {
                     await provider.manager.update(amount: amount)
                 }
             }
         }
         */

        return _providers
    }

    public func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func makeProvider(item: OnrampPairRequestItem, provider: OnrampPair.Provider) -> OnrampProvider {
        // Construct a OnrampProvider wrapper with autoupdating itself
        // TODO: https://tangem.atlassian.net/browse/IOS-8310
        OnrampProvider(provider: provider)
    }
}
