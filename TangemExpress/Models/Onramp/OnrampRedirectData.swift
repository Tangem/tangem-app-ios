//
//  OnrampRedirectData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectData: Hashable, Decodable {
    let fromCurrencyCode: String
    let toContractAddress: String
    let toNetwork: String
    let paymentMethod: String
    let countryCode: String
    let fromAmount: String
    let toAmount: String?
    let toDecimals: Int
    let providerId: String
    let toAddress: String
    let redirectUrl: String
    let language: String?
    let theme: String?
    let requestId: String
    let externalTxId: String
    let widgetUrl: String
}
