//
//  ExchangeData.swift
//  Tangem
//
//  Created by Pavel Grechikhin.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeData: Decodable {
    public let fromToken: ExchangeTokenData
    public let toToken: ExchangeTokenData
    public let toTokenAmount: String
    public let fromTokenAmount: String
    public let protocols: [[[ProtocolInfo]]]
    public let tx: TransactionData
}

public struct ExchangeTokenData: Decodable {
    public let symbol: String
    public let name: String
    public let decimals: Int
    public let address: String
    public let logoURI: String
}

public struct TransactionData: Codable {
    public let from: String
    public let to: String
    public let data: String
    public let value: String
    public let gas: Int
    public let gasPrice: String
}
