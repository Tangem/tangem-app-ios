//
//  OnrampPairRequestItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPairRequestItem {
    public let fiatCurrency: OnrampFiatCurrency
    public let country: OnrampCountry
    public let destination: ExpressWallet

    public init(
        fiatCurrency: OnrampFiatCurrency,
        country: OnrampCountry,
        destination: ExpressWallet
    ) {
        self.fiatCurrency = fiatCurrency
        self.country = country
        self.destination = destination
    }
}
