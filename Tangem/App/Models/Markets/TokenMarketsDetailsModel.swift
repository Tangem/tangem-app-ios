//
//  TokenMarketsDetailsModel.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsDetailsModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let isActive: Bool
    let currentPrice: Decimal
    let shortDescription: String?
    let fullDescription: String?
    let priceChangePercentage: [String: Decimal]
    let insights: TokenMarketsDetailsInsights?
    let metrics: MarketsTokenDetailsMetrics?
    let coinModel: CoinModel
    let pricePerformance: [MarketsPriceIntervalType: MarketsPricePerformanceData]
    let links: MarketsTokenDetailsLinks
}

struct TokenMarketsDetailsInsights {
    let holders: [MarketsPriceIntervalType: Decimal]
    let liquidity: [MarketsPriceIntervalType: Decimal]
    let buyPressure: [MarketsPriceIntervalType: Decimal]
    let experiencedBuyers: [MarketsPriceIntervalType: Decimal]

    init?(dto: MarketsDTO.Coins.Insights?) {
        guard let dto else {
            return nil
        }

        func mapToInterval(_ dict: [String: Decimal?]) -> [MarketsPriceIntervalType: Decimal] {
            return dict.reduce(into: [:]) { partialResult, pair in
                guard
                    let interval = MarketsPriceIntervalType(rawValue: pair.key),
                    let value = pair.value
                else {
                    return
                }

                partialResult[interval] = value
            }
        }

        holders = mapToInterval(dto.holdersChange)
        liquidity = mapToInterval(dto.liquidityChange)
        buyPressure = mapToInterval(dto.buyPressureChange)
        experiencedBuyers = mapToInterval(dto.experiencedBuyerChange)
    }
}
