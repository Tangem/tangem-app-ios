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
        let priceChangePercentage: PriceChangePercentage
        let networks: [Network]
        let shortDescription: String?
        let fullDescription: String?
        let insights: [Insight]?
        let metrics: Metrics
        let links: Links
        let pricePerformance: PricePerformance
    }

    struct PriceChangePercentage: Codable {
        let day: Decimal
        let week: Decimal
        let month: Decimal
        let threeMonths: Decimal
        let sixMonths: Decimal
        let year: Decimal
        let allTime: Decimal
    }

    struct Network: Codable {
        let networkId: String
        let exchangeable: Bool
        let contractAddress: String
        let decimalCount: Decimal
    }

    struct Insight: Codable {
        let holdersChange: Change
        let liquidityChange: Change
        let buyPressureChange: Change
        let experiencedBuyerChange: Change
    }

    struct Change: Codable {
        let day: Decimal
        let week: Decimal
        let month: Decimal
    }

    struct Metrics: Codable {
        let marketRating: Decimal
        let circulatingSupply: Decimal
        let marketCap: Decimal
        let volume24h: Decimal
        let totalSupply: Decimal
        let fullyDilutedValuation: Decimal
    }

    struct Links: Codable {
        let homepage: [String?]
        let blockchainSite: [String?]
        let whitepaper: String?
        let reddit: String?
        let officialForum: [String?]
        let chat: [String?]
        let community: [String?]
        let repository: [String?]
    }

    struct PricePerformance: Codable {
        let highPrice: Price
        let lowPrice: Price
    }

    struct Price: Codable {
        let day: Decimal
        let month: Decimal
        let allTime: Decimal
    }
}
