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
        let metrics: Metrics
        let links: Links
        let pricePerformance: PricePerformance
    }

    struct Network: Codable {
        let networkId: String
        let exchangeable: Bool
        let contractAddress: String?
        let decimalCount: Decimal?
    }

    struct Insight: Codable {
        let holdersChange: [String: Decimal]
        let liquidityChange: [String: Decimal]
        let buyPressureChange: [String: Decimal]
        let experiencedBuyerChange: [String: Decimal]
    }

    struct Metrics: Codable {
        let marketRating: Decimal
        let circulatingSupply: Decimal
        let marketCap: Decimal
        let volume24H: Decimal
        let totalSupply: Decimal
        let fullyDilutedValuation: Decimal?
    }

    struct Links: Codable {
        let homepage: [String]?
        let blockchainSite: [String]?
        let whitepaper: String?
        let reddit: String?
        let officialForum: [String]?
        let chat: [String]?
        let community: [String]?
        let reposUrl: [String: [String]]?
    }

    struct PricePerformance: Codable {
        let highPrice: [String: Decimal]
        let lowPrice: [String: Decimal]
    }
}
