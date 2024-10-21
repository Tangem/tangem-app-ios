//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public actor CommonOnrampManager {
    private let provider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
    private let logger: Logger

    private var _providers: [OnrampProvider] = []

    public init(
        provider: ExpressAPIProvider,
        onrampRepository: OnrampRepository,
        logger: Logger
    ) {
        self.provider = provider
        self.onrampRepository = onrampRepository
        self.logger = logger
    }
}

// MARK: - OnrampManager

extension CommonOnrampManager: OnrampManager {
    public func updateCountry() async throws -> OnrampCountry {
        // Define country by ip or get from repository
        // https://tangem.atlassian.net/browse/IOS-8267

        throw OnrampManagerError.notImplement
    }

    public func updatePaymentMethod() async throws -> OnrampPaymentMethod {
        // Load payment methods
        // Or get it from repository (?)
        throw OnrampManagerError.notImplement
    }

    public func update(pair: OnrampPair) async throws -> [OnrampProvider] {
        // Load providers from API
        // Make provides
        // Save providers
        throw OnrampManagerError.notImplement
    }

    public func update(amount: Decimal) async throws -> [OnrampProvider] {
        for provider in _providers {
            _ = await provider.manager.update(amount: amount)
        }

        return _providers
    }

    public func loadOnrampData(request: OnrampQuotesRequest) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}
