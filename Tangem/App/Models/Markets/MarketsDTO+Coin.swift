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

    struct Response: Decodable {
        let id: String
        let name: String
        let symbol: String
        let active: Bool
        let currentPrice: Decimal
        // We need to use here Decimal? otherwise iOS 17.6 and iOS 18 Beta can't parse response with null values
        let priceChangePercentage: [String: Decimal?]
        let networks: [NetworkModel]?
        let shortDescription: String?
        let fullDescription: String?
        let exchangesAmount: Int?
        let insights: Insights?
        let links: MarketsTokenDetailsLinks?
        let metrics: MarketsTokenDetailsMetrics?
        let securityData: SecurityData?
        let pricePerformance: [String: MarketsPricePerformanceData]?
    }

    struct Insights: Decodable {
        let holdersChange: [String: Decimal?]
        let liquidityChange: [String: Decimal?]
        let buyPressureChange: [String: Decimal?]
        let experiencedBuyerChange: [String: Decimal?]
        let networks: [MarketsInsightsNetworkInfo]?
    }

    struct SecurityData: Decodable {
        struct ProviderData: Decodable {
            let providerId: String
            let providerName: String
            let securityScore: Double
            let link: URL?
            let lastAuditDate: Date?
        }

        let totalSecurityScore: Double?
        let providerData: [ProviderData]?
    }
}
