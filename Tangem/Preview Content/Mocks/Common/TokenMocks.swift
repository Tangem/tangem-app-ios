//
//  TokenMocks.swift
//  Tangem
//
//  Created by Andrew Son on 20/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Token {
    static var tetherMock: Token {
        Token(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
            decimalCount: 6,
            id: "tether"
        )
    }

    static var sushiMock: Token {
        Token(
            name: "Sushi",
            symbol: "SUSHI",
            contractAddress: "0x0b3f868e0be5597d5db7feb59e1cadbb0fdda50a",
            decimalCount: 18,
            id: "sushi"
        )
    }

    static var inverseBTCBlaBlaBlaMock: Token {
        Token(
            name: "Inverse BTC Flexible Leverage Index",
            symbol: "IBTC-FLI-P",
            contractAddress: "0x130ce4e4f76c2265f94a961d70618562de0bb8d2",
            decimalCount: 18,
            id: "inverse-btc-flexible-leverage-index"
        )
    }

    static var shibaInuMock: Token {
        Token(
            name: "Shiba Inu",
            symbol: "SHIB",
            contractAddress: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
            decimalCount: 18,
            id: "shiba-inu"
        )
    }

    static var polygonTokenMock: Token {
        Token(
            name: "Polygon",
            symbol: "MATIC",
            contractAddress: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
            decimalCount: 18,
            id: "matic-network"
        )
    }

    static var cosmosMock: Token {
        Token(
            name: "Cosmos Hub",
            symbol: "ATOM",
            contractAddress: "0xac51C4c48Dc3116487eD4BC16542e27B5694Da1b",
            decimalCount: 6,
            id: "cosmos"
        )
    }
}
