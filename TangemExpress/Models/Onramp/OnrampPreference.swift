//
//  OnrampPreference.swift
//  TangemApp
//
//  Created by Sergey Balashov on 21.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPreference: Hashable {
    public let country: OnrampCountry?
    public let currency: OnrampFiatCurrency?

    public init(country: OnrampCountry?, currency: OnrampFiatCurrency?) {
        self.country = country
        self.currency = currency
    }
}

public extension OnrampPreference {
    var isEmpty: Bool {
        country == nil && currency == nil
    }
}
