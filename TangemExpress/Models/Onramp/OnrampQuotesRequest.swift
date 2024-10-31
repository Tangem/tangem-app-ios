//
//  OnrampSwappableItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampSwappableItem {
    public let fiatCurrency: OnrampFiatCurrency
    public let country: OnrampCountry
    public let destination: ExpressWallet
    public let paymentMethod: OnrampPaymentMethod
    public let providerInfo: ProviderInfo
    public let amount: Decimal
    public let redirectSettings: OnrampRedirectSettings

    public init(
        fiatCurrency: OnrampFiatCurrency,
        country: OnrampCountry,
        destination: ExpressWallet,
        paymentMethod: OnrampPaymentMethod,
        providerInfo: ProviderInfo,
        amount: Decimal,
        redirectSettings: OnrampRedirectSettings
    ) {
        self.fiatCurrency = fiatCurrency
        self.country = country
        self.destination = destination
        self.paymentMethod = paymentMethod
        self.providerInfo = providerInfo
        self.amount = amount
        self.redirectSettings = redirectSettings
    }

    func sourceAmountWEI() -> String {
        let wei = (amount * pow(10, fiatCurrency.precision)) as NSDecimalNumber
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
