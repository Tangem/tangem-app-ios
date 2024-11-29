//
//  OnrampProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public class OnrampProvider {
    public let provider: ExpressProvider
    public let paymentMethod: OnrampPaymentMethod

    public private(set) var attractiveType: AttractiveType?

    private let manager: OnrampProviderManager

    init(
        provider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        manager: OnrampProviderManager
    ) {
        self.provider = provider
        self.paymentMethod = paymentMethod
        self.manager = manager
    }

    func update(attractiveType: AttractiveType?) {
        self.attractiveType = attractiveType
    }
}

public extension OnrampProvider {
    enum AttractiveType: Hashable, CustomStringConvertible {
        case best
        case loss(percent: Decimal)

        public var description: String {
            switch self {
            case .best: "Best"
            case .loss(let percent): "Loss \(percent)"
            }
        }
    }
}

// MARK: - OnrampProviderManagerProxy

extension OnrampProvider: OnrampProviderManager {
    public var state: OnrampProviderManagerState { manager.state }

    public var isSupported: Bool {
        state.isSupported
    }

    /// Can be used for showing user
    public var isShowable: Bool {
        switch state {
        case .idle, .restriction, .loaded: true
        case .loading, .failed, .notSupported: false
        }
    }

    /// Can be used as `_selectedProvider`
    public var isSelectable: Bool {
        switch state {
        case .idle, .loading, .restriction, .loaded, .failed: true
        case .notSupported: false
        }
    }

    public var isSuccessfullyLoaded: Bool {
        switch state {
        case .loaded: true
        case .idle, .loading, .failed, .notSupported, .restriction: false
        }
    }

    public var quote: OnrampQuote? {
        switch state {
        case .loaded(let quote): quote
        case .restriction, .failed, .idle, .loading, .notSupported: nil
        }
    }

    public var error: Error? {
        switch state {
        case .failed(let error): error
        case .restriction, .loaded, .idle, .loading, .notSupported: nil
        }
    }

    public func update(amount: Decimal?) async {
        await manager.update(amount: amount)
    }

    public func makeOnrampQuotesRequestItem() throws -> OnrampQuotesRequestItem {
        try manager.makeOnrampQuotesRequestItem()
    }
}

// MARK: - CustomStringConvertible

extension OnrampProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: [
            "provider": provider.name,
            "paymentMethod": paymentMethod.name,
            "manager.state": manager.state,
            "attractiveType": attractiveType as Any,
        ])
    }
}
