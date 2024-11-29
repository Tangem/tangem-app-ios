//
//  OnrampRedirectData.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectData: Codable, Equatable {
    public let txId: String
    public let widgetUrl: URL
    public let fromAmount: Decimal
    public let fromCurrencyCode: String
    public let externalTxId: String
}
