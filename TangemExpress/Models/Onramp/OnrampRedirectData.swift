//
//  OnrampRedirectData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectDataWithId {
    public let txId: String
    public let redirectData: OnrampRedirectData
}

public struct OnrampRedirectData: Hashable, Decodable {
    public let fromCurrencyCode: String
    public let toContractAddress: String
    public let toNetwork: String
    public let paymentMethod: String
    public let countryCode: String
    public let fromAmount: String
    public let toAmount: String?
    public let toDecimals: Int
    public let providerId: String
    public let toAddress: String
    public let redirectUrl: URL
    public let language: String?
    public let theme: String?
    public let requestId: String
    public let externalTxId: String
    public let widgetUrl: URL
}
