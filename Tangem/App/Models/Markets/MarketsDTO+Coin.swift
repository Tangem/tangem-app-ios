//
//  MarketsDTO+Coin.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsDTO {
    enum Coins {}
}

extension MarketsDTO.Coins {
    struct Request: Encodable {
        let tokenId: TokenItemId
        let currency: String
        let language: String
    }

    struct Response: Codable {
        let id: String
        let name: String
        let symbol: String
        let active: Bool
        let currentPrice: Decimal
        let priceChangePercentage: [String: Decimal]
        let networks: [Network]?
        let shortDescription: String?
        let fullDescription: String?
        let insights: [Insight]?
        let links: Links
        let metrics: MarketsTokenDetailsMetrics?
        let pricePerformance: PricePerformance
    }

    struct Network: Codable {
        let networkId: String
        let exchangeable: Bool
        let contractAddress: String?
        let decimalCount: Int?
    }

    struct Insight: Codable {
        let holdersChange: [String: Decimal]
        let liquidityChange: [String: Decimal]
        let buyPressureChange: [String: Decimal]
        let experiencedBuyerChange: [String: Decimal]
    }

    struct Links: Codable {
        let homepage: [String]?
        let whitepaper: String?
        let subredditUrl: String?
        let officialForumUrl: [String]?
        let chat: [String]?
        let community: [String]?
        let reposUrl: [String: [String]]?
        let twitterScreenName: String?
        let facebookUsername: String?
    }

    struct PricePerformance: Codable {
        let highPrice: [String: Decimal]
        let lowPrice: [String: Decimal]
    }
}

// "links": { // каждый параметр объекта может содерджать пустое значение
//    "homepage": [ //массив значений
//        "http://www.bitcoin.org"
//    ],
//    "blockchain_site": [ //массив значений
//        "https://mempool.space/",
//        "https://blockchair.com/bitcoin/"
//    ],
//    "whitepaper": "https://bitcoin.org/bitcoin.pdf",
//    "reddit": "https://www.reddit.com/r/Bitcoin/",
//    "official_forum": [], //массив значений
//    "chat": [], //массив значений
//    "community": [ //массив значений
//        "https://twitter.com/Bitcoin",
//        "https://www.facebook.com/buy.bitcoin.news/"
//    ],
//    "repository": [] //массив значений
//    }
