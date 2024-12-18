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

    public func hasSelectableProviders() -> Bool {
        providers.filter { $0.isShowable && $0.isSelectable }.isNotEmpty
    }

    /// Provider which can be showed and selected
    public func maxPriorityProvider() -> OnrampProvider? {
        providers.first(where: { $0.isShowable && $0.isSelectable })
    }

    /// Provider which can be selected by user
    public func selectableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isSelectable })
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        let sorter = ProviderItemSorter()
        providers.sort(by: { sorter.sort(lhs: $0, rhs: $1) })
        // Return sorted providers
        return providers
    }

    /// Providers will be sorted and their `attractiveType` will be updated
    public func updateAttractiveTypes() {
        // Only if we have more than one providers with quote
        guard providers.filter(\.isSuccessfullyLoaded).count > 1 else {
            providers.forEach { $0.update(attractiveType: .none) }
            return
        }

        var bestQuote: Decimal?

        sort().indexed().forEach { index, provider in
            switch (index, provider.state) {
            case (.zero, .loaded(let quote)):
                provider.update(attractiveType: .best)
                bestQuote = quote.expectedAmount

            case (_, .loaded(let quote)) where bestQuote != nil:
                let percent = quote.expectedAmount / bestQuote! - 1
                provider.update(attractiveType: .loss(percent: percent))

            case (_, _):
                provider.update(attractiveType: .none)
            }
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

    func sorted() -> Self {
        forEach { $0.sort() }

        return sorted { lhs, rhs in
            // If paymentMethod has same priority (e.g. SEPA and Revolut Pay)
            guard lhs.paymentMethod.type.priority == rhs.paymentMethod.type.priority else {
                return lhs.paymentMethod.type.priority > rhs.paymentMethod.type.priority
            }

            switch (lhs.providers.first, rhs.providers.first) {
            case (.some(let lhsProvider), .some(let rhsProvider)):
                return ProviderItemSorter().sort(lhs: lhsProvider, rhs: rhsProvider)
            case (.none, _), (_, .none):
                return false
            }
        }
    }

    func updateSupportedPaymentMethods() {
        forEach { item in
            item.providers.forEach { provider in
                if case .notSupported(.paymentMethod) = provider.state {
                    let supportedMethods = filter { $0.providers.contains { $0.isSuccessfullyLoaded } }.map(\.paymentMethod)
                    provider.update(supportedMethods: supportedMethods)
                }
            }
        }
    }
}
