//
//  OnrampIdentityMock.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

extension OnrampIdentity {
    static let usa = OnrampIdentity(name: "USA", code: "US", image: IconURLBuilder().fiatIconURL(currencyCode: "USD"))
    static let pt = OnrampIdentity(name: "Portugal", code: "PT", image: IconURLBuilder().fiatIconURL(currencyCode: "EUR"))

    static let usd = OnrampIdentity(name: "USD", code: "USD", image: IconURLBuilder().fiatIconURL(currencyCode: "USD"))
    static let eur = OnrampIdentity(name: "Euro", code: "EUR", image: IconURLBuilder().fiatIconURL(currencyCode: "EUR"))
}
