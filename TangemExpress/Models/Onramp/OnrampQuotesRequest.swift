//
//  OnrampSwappableItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampSwappableItem {
    public let source: OnrampCountry
    public let destination: ExpressWallet
    public let paymentMethod: OnrampPaymentMethod
    public let providerInfo: ProviderInfo
    public let amount: Decimal
    public let redirectSettings: OnrampRedirectSettings

    public init(
        source: OnrampCountry,
        destination: ExpressWallet,
        paymentMethod: OnrampPaymentMethod,
        providerInfo: ProviderInfo,
        amount: Decimal,
        redirectSettings: OnrampRedirectSettings
    ) {
        self.source = source
        self.destination = destination
        self.paymentMethod = paymentMethod
        self.providerInfo = providerInfo
        self.amount = amount
        self.redirectSettings = redirectSettings
    }

    func sourceAmountWEI() -> String {
        let wei = (amount * pow(10, 2)) as NSDecimalNumber
        return wei.stringValue
    }

    func destinationAmountWEI() -> String {
        let wei = destination.convertToWEI(value: amount) as NSDecimalNumber
        return wei.stringValue
    }
}

public extension OnrampSwappableItem {
    struct ProviderInfo: Hashable {
        let id: String
    }
}
