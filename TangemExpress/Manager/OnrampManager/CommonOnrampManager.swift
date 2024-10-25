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

    private var _providers: [Provider] = []

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

    public func setupProviders(request: OnrampPairRequestItem) async throws {
        let pairs = try await apiProvider.onrampPairs(
            from: request.fiatCurrency,
            to: [request.destination.expressCurrency],
            country: request.country
        )

        _providers = pairs.flatMap { $0.providers }.map { provider in
            makeProvider(item: request, provider: provider)
        }
    }

    public func setupQuotes(amount: Decimal) async throws {
        await withTaskGroup(of: Void.self) { [weak self] group in
            await self?._providers.forEach { provider in
                _ = group.addTaskUnlessCancelled {
                    await provider.manager.update(amount: amount)
                }
            }
        }
    }

    public func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func makeProvider(item: OnrampPairRequestItem, provider: OnrampProvider) -> Provider {
        Provider(
            manager: CommonOnrampProviderManager(
                item: item,
                provider: provider,
                dataRepository: dataRepository,
                apiProvider: apiProvider
            )
        )
    }
}

private extension CommonOnrampManager {
    struct Provider {
        let manager: OnrampProviderManager
    }
}
