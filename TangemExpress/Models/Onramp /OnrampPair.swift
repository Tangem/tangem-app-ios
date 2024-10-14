//
//  OnrampPair.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPair {
    public let item: ExpressWallet
    public let currency: OnrampCurrency

    public init(item: ExpressWallet, currency: OnrampCurrency) {
        self.item = item
        self.currency = currency
    }
}

// MARK: - Hashable

extension OnrampPair: Hashable {
    public static func == (lhs: OnrampPair, rhs: OnrampPair) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(item.expressCurrency)
        hasher.combine(currency)
    }
}
