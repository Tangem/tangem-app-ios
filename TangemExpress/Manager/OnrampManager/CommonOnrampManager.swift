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
    public func getCountry() async throws -> OnrampCountry {
        if let country = onrampRepository.savedCountry {
            return country
        }

        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
        let country: OnrampCountry = .random() ? .rus : .usa

        onrampRepository.updatePreference(country: country)
        return country
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
        return _providers
    }

    public func loadOnrampData(request: OnrampSwappableItem) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}

// TEMP MOCK

extension OnrampCountry {
    static let usa = OnrampCountry(identity: .usa, currency: .init(identity: .usa), onrampAvailable: true)
    static let rus = OnrampCountry(identity: .rus, currency: .init(identity: .rus), onrampAvailable: false)
}

extension OnrampIdentity {
    static let usa = OnrampIdentity(
        name: "USA",
        code: "US",
        image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/currencies/medium/usd.png")!
    )

    static let rus = OnrampIdentity(
        name: "Russia",
        code: "RU",
        image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/currencies/medium/rub.png")!
    )
}
