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

    public func hasShowableProviders() -> Bool {
        providers.filter { $0.isShowable }.isNotEmpty
    }

    public func showableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isShowable })
    }

    public func selectableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isSelectable })
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        providers.sort(by: { sort(lhs: $0, rhs: $1) })
        // Return sorted providers
        return providers
    }

    /// Providers will be sorted
    @discardableResult
    public func updateBest() -> OnrampProvider? {
        if let best = sort().first(where: { $0.isSuccessfullyLoaded }) {
            best.update(isBest: true)
            return best
        }

        return nil
    }

    private func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        switch (lhs.state, rhs.state) {
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)):
            return lhsQuote.expectedAmount > rhsQuote.expectedAmount
        // All cases which is not `loaded` have to be ordered after
        case (_, .loaded):
            return false
        // All cases which is `loaded` have to be ordered before `rhs`
        // All cases which is `restriction` have to be ordered before `rhs`
        // Exclude case where `rhs == .loaded`. This case processed above
        case (.loaded, _), (.restriction, _):
            return true
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
