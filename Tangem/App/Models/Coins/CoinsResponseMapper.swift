//
//  CoinsResponseMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CoinsResponseMapper {
    let supportedBlockchains: Set<Blockchain>

    private let tokenItemMapper: TokenItemMapper

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
        tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
    }

    func mapToCoinModels(_ response: CoinsList.Response) -> [CoinModel] {
        response.coins.compactMap { coin in
            let id = coin.id.trimmed()
            let name = coin.name.trimmed()
            let symbol = coin.symbol.uppercased().trimmed()

            let items: [CoinModel.Item] = coin.networks.compactMap { network in
                guard let item = tokenItemMapper.mapToTokenItem(id: id, name: name, symbol: symbol, network: network) else {
                    return nil
                }

                return CoinModel.Item(id: id, tokenItem: item, exchangeable: network.exchangeable)
            }

            if items.isEmpty {
                return nil
            }

            return CoinModel(id: id, name: name, symbol: symbol, items: items)
        }
    }
}
