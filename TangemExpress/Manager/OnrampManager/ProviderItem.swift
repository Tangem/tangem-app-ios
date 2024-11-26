//
//  ProviderItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public typealias ProvidersList = [ProviderItem]

public class ProviderItem {
    public let paymentMethod: OnrampPaymentMethod
    public private(set) var providers: [OnrampProvider]

    init(paymentMethod: OnrampPaymentMethod, providers: [OnrampProvider]) {
        self.paymentMethod = paymentMethod
        self.providers = providers
    }

    public func hasProviders() -> Bool {
        providers.filter { $0.canBeShow }.isNotEmpty
    }

    /// First provider with `canBeSelected == true` flag
    public func providerForAutoSelect() -> OnrampProvider? {
        providers.first(where: { $0.canBeSelected })
    }

    /// First provider with `canBeShow == true` flag
    public func providerForShow() -> OnrampProvider? {
        providers.first(where: { $0.canBeShow })
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        providers.sort(by: { sort(lhs: $0, rhs: $1) })
        // Return sorted providers
        return providers
    }

    /// Providers has to be already sorted
    @discardableResult
    public func updateBest() -> OnrampProvider? {
        if let best = providers.first(where: { $0.isReadyToBuy }) {
            best.update(isBest: true)
            return best
        }

        return nil
    }

    private func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        switch (lhs.state, rhs.state) {
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)):
            return lhsQuote.expectedAmount > rhsQuote.expectedAmount
        case (.restriction, _):
            return true
        case (_, .restriction):
            return false
        default:
            return false
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension ProviderItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        TangemFoundation.objectDescription(self, userInfo: [
            "paymentMethod": paymentMethod.name,
            "providers": providers.map {
                "providerName: \($0.provider.name), state: \($0.state)"
            },
        ])
    }
}

// MARK: - Array<ProviderItem>

public extension ProvidersList {
    func hasProviders() -> Bool {
        !flatMap { $0.providers }.isEmpty
    }

    func select(for paymentMethod: OnrampPaymentMethod) -> ProviderItem? {
        first(where: { $0.paymentMethod == paymentMethod })
    }
}
