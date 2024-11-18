//
//  ProviderItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public class ProviderItem {
    public let paymentMethod: OnrampPaymentMethod
    public private(set) var providers: [OnrampProvider]

    init(paymentMethod: OnrampPaymentMethod, providers: [OnrampProvider]) {
        self.paymentMethod = paymentMethod
        self.providers = providers
    }

    public func suggestProvider() -> OnrampProvider? {
        // Has to sort again ?
        return providers.first(where: { $0.manager.state.canBeShow })
    }

    public func sort() {
        providers.sort(by: { sort(lhs: $0.manager.state, rhs: $1.manager.state) })
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

public extension Array where Element == ProviderItem {
    func hasProviders() -> Bool {
        !flatMap { $0.providers }.isEmpty
    }

    func select(for paymentMethod: OnrampPaymentMethod) -> ProviderItem? {
        first(where: { $0.paymentMethod == paymentMethod })
    }
}
