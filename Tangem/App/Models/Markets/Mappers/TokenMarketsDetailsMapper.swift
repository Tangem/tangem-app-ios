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

    func map(response: MarketsDTO.Coins.Response) -> TokenMarketsDetailsModel {
        TokenMarketsDetailsModel(
            id: response.id,
            name: response.name,
            symbol: response.symbol,
            isActive: response.active,
            currentPrice: response.currentPrice,
            shortDescription: response.shortDescription,
            fullDescription: response.fullDescription,
            priceChangePercentage: response.priceChangePercentage,
            insights: .init(dto: response.insights),
            metrics: response.metrics,
            pricePerformance: mapPricePerformance(response: response),
            links: response.links,
            availableNetworks: response.networks ?? []
        )
    }

    // MARK: - Private Implementation

    private func mapPricePerformance(response: MarketsDTO.Coins.Response) -> [MarketsPriceIntervalType: MarketsPricePerformanceData] {
        return response.pricePerformance.reduce(into: [:]) { partialResult, pair in
            guard let intervalType = MarketsPriceIntervalType(rawValue: pair.key) else {
                return
            }

            partialResult[intervalType] = pair.value
        }
    }
}
