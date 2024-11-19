//
//  OnrampQuotesRequestItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampQuotesRequestItem {
    public let pairItem: OnrampPairRequestItem
    public let paymentMethod: OnrampPaymentMethod
    public let providerInfo: ProviderInfo
    public let amount: Decimal

    public init(
        pairItem: OnrampPairRequestItem,
        paymentMethod: OnrampPaymentMethod,
        providerInfo: ProviderInfo,
        amount: Decimal
    ) {
        self.pairItem = pairItem
        self.paymentMethod = paymentMethod
        self.providerInfo = providerInfo
        self.amount = amount
    }

    func sourceAmountWEI() -> String {
        let wei = (amount * pow(10, pairItem.fiatCurrency.precision)) as NSDecimalNumber
        return wei.stringValue
    }

    func destinationAmountWEI() -> String {
        let wei = pairItem.destination.convertToWEI(value: amount) as NSDecimalNumber
        return wei.stringValue
    }
}

public extension OnrampQuotesRequestItem {
    struct ProviderInfo: Hashable {
        let id: String
    }
}
