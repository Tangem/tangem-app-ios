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
            coinModel: mapToCoinModel(response: response),
            pricePerformance: mapPricePerformance(response: response),
            links: response.links
        )
    }

    // MARK: - Private Implementation

    private func mapToCoinModel(response: MarketsDTO.Coins.Response) -> CoinModel {
        let id = response.id.trimmed()
        let name = response.name.trimmed()
        let symbol = response.symbol.uppercased().trimmed()

        let items: [CoinModel.Item] = response.networks?.compactMap { network in
            guard let item = tokenItemMapper.mapToTokenItem(
                id: id,
                name: name,
                symbol: symbol,
                network: NetworkModel(
                    networkId: network.networkId,
                    contractAddress: network.contractAddress,
                    decimalCount: network.decimalCount,
                    exchangeable: network.exchangeable
                )
            ) else {
                return nil
            }

            return CoinModel.Item(id: id, tokenItem: item, exchangeable: network.exchangeable)
        } ?? []

        return CoinModel(id: id, name: name, symbol: symbol, items: items)
    }

    private func mapPricePerformance(response: MarketsDTO.Coins.Response) -> [MarketsPriceIntervalType: MarketsPricePerformanceData] {
        return response.pricePerformance.reduce(into: [:]) { partialResult, pair in
            guard let intervalType = MarketsPriceIntervalType(rawValue: pair.key) else {
                return
            }

            partialResult[intervalType] = pair.value
        }
    }
}
