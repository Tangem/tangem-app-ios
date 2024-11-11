//
//  MarketsTokenDetailsModel.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let isActive: Bool
    let currentPrice: Decimal
    let shortDescription: String?
    let fullDescription: String?
    let numberOfExchangesListedOn: Int?
    let priceChangePercentage: [String: Decimal]
    let insights: MarketsTokenDetailsInsights?
    let metrics: MarketsTokenDetailsMetrics?
    let securityScore: MarketsTokenDetailsSecurityScore?
    let pricePerformance: [MarketsPriceIntervalType: MarketsPricePerformanceData]?
    let links: MarketsTokenDetailsLinks?
    let availableNetworks: [NetworkModel]
}

extension MarketsTokenDetailsModel: Equatable {
    // This model won't be reloaded for now (no PTR or some kind of refresh mechanism),
    // so it is safe to compare this fields.
    static func == (lhs: MarketsTokenDetailsModel, rhs: MarketsTokenDetailsModel) -> Bool {
        return lhs.id == rhs.id
            && lhs.insights == rhs.insights
            && lhs.metrics == rhs.metrics
            && lhs.pricePerformance == rhs.pricePerformance
            && lhs.links == rhs.links
            && lhs.securityScore == rhs.securityScore
    }
}

struct MarketsTokenDetailsInsights: Equatable {
    let holders: [MarketsPriceIntervalType: Decimal]
    let liquidity: [MarketsPriceIntervalType: Decimal]
    let buyPressure: [MarketsPriceIntervalType: Decimal]
    let experiencedBuyers: [MarketsPriceIntervalType: Decimal]
    let networksInfo: [MarketsInsightsNetworkInfo]?

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
        networksInfo = dto.networks
    }
}

struct MarketsTokenDetailsSecurityScore: Equatable {
    struct Provider: Equatable {
        let id: String
        let name: String
        let securityScore: Double
        let auditURL: URL?
        let auditDate: Date?
    }

    let securityScore: Double
    let providers: [Provider]
}
