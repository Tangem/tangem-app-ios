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
            tokenItems: mapToTokenItems(response: response),
            insights: .init(dto: response.insights?.first),
            metrics: response.metrics
        )
    }

    // MARK: - Private Implementation

    private func mapToTokenItems(response: MarketsDTO.Coins.Response) -> [TokenItem] {
        let id = response.id.trimmed()
        let name = response.name.trimmed()
        let symbol = response.symbol.uppercased().trimmed()

        let items: [TokenItem] = response.networks?.compactMap { network in
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

            return item
        } ?? []

        return items
    }
}
