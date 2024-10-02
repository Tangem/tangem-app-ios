//
//  OnrampPair.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPair: Hashable {
    public let item: ExpressWallet
    public let currency: OnrampCurrency

    public init(item: ExpressWallet, currency: OnrampCurrency) {
        self.item = item
        self.currency = currency
    }
}
