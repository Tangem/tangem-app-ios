//
//  TokenMarketsDetailsMapper.swift
//  Tangem
//
//  Created by skibinalexander on 03.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenMarketsDetailsMapper {
    let supportedBlockchains: Set<Blockchain>

    private let tokenItemMapper: TokenItemMapper

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
        tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
    }

    func map(response: MarketsDTO.Coins.Response) throws -> TokenMarketsDetailsModel {
        return TokenMarketsDetailsModel(
            id: response.id,
            name: response.name,
            symbol: response.symbol,
            isActive: response.active,
            currentPrice: response.currentPrice,
            shortDescription: response.shortDescription,
            fullDescription: response.fullDescription,
            priceChangePercentage: try mapPriceChangePercentage(response: response),
            insights: .init(dto: response.insights),
            metrics: response.metrics,
            pricePerformance: mapPricePerformance(response: response),
            links: response.links,
            availableNetworks: response.networks ?? []
        )
    }

    // MARK: - Private Implementation

    private func mapPriceChangePercentage(response: MarketsDTO.Coins.Response) throws -> [String: Decimal] {
        var percentage = response.priceChangePercentage

        guard let allTimeValue = percentage[MarketsPriceIntervalType.all.rawValue] else {
            throw MapperError.missingAllTimePriceChangeValue
        }

        MarketsPriceIntervalType.allCases.forEach {
            guard percentage[$0.rawValue] == nil else {
                return
            }

            percentage[$0.rawValue] = allTimeValue
        }
        return percentage
    }

    private func mapPricePerformance(response: MarketsDTO.Coins.Response) -> [MarketsPriceIntervalType: MarketsPricePerformanceData]? {
        return response.pricePerformance?.reduce(into: [:]) { partialResult, pair in
            guard let intervalType = MarketsPriceIntervalType(rawValue: pair.key) else {
                return
            }

            partialResult[intervalType] = pair.value
        }
    }
}

extension TokenMarketsDetailsMapper {
    enum MapperError: Error {
        case missingAllTimePriceChangeValue
    }
}
