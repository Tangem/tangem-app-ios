//
//  ProviderItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public class ProviderItem {
    public let paymentMethod: OnrampPaymentMethod
    public private(set) var providers: [OnrampProvider]

    init(paymentMethod: OnrampPaymentMethod, providers: [OnrampProvider]) {
        self.paymentMethod = paymentMethod
        self.providers = providers
    }

    public func suggestProvider() -> OnrampProvider? {
        providers.first(where: { $0.manager.state.canBeShow }) ?? providers.first
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        providers.sort(by: { sort(lhs: $0.manager.state, rhs: $1.manager.state) })
        // Return sorted providers
        return providers
    }

    /// Providers has to be already sorted
    @discardableResult
    public func updateBest() -> OnrampProvider? {
        if let best = providers.first(where: { $0.manager.state.isReadyToBuy }) {
            best.update(isBest: true)
            return best
        }

        return nil
    }

    private func sort(lhs: OnrampProviderManagerState, rhs: OnrampProviderManagerState) -> Bool {
        switch (lhs, rhs) {
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
                "providerName: \($0.provider.name), state: \($0.manager.state)"
            },
        ])
    }
}

// MARK: - Array<ProviderItem>

public extension Array where Element == ProviderItem {
    func hasProviders() -> Bool {
        !flatMap { $0.providers }.isEmpty
    }

    func select(for paymentMethod: OnrampPaymentMethod) -> ProviderItem? {
        first(where: { $0.paymentMethod == paymentMethod })
    }
}
