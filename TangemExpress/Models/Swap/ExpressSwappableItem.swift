//
//  ExpressSwappableItem.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressSwappableItem {
    public let source: ExpressWallet
    public let destination: ExpressWallet
    public let amount: Decimal
    public let providerInfo: ProviderInfo

    public init(
        source: ExpressWallet,
        destination: ExpressWallet,
        amount: Decimal,
        providerInfo: ProviderInfo
    ) {
        self.source = source
        self.destination = destination
        self.amount = amount
        self.providerInfo = providerInfo
    }

    func sourceAmountWEI() -> String {
        let wei = source.convertToWEI(value: amount) as NSDecimalNumber
        return wei.stringValue
    }
}

public extension ExpressSwappableItem {
    struct ProviderInfo {
        let id: ExpressProvider.Id
        let type: ExpressProviderType
    }
}
