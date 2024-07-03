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

    func mapToTokenItems(tokenMarketsDetails model: TokenMarketsDetailsModel) -> [TokenItem] {
        let id = model.id.trimmed()
        let name = model.name.trimmed()
        let symbol = model.symbol.uppercased().trimmed()

        let items: [TokenItem] = model.networks.compactMap { network in
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
        }

        return items
    }
}
