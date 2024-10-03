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
        let l2Blockchains = SupportedBlockchains.l2Blockchains

        return response.coins.compactMap { coin in
            let id = coin.id.trimmed()

            // ignore l2 coin
            if l2Blockchains.contains(where: { $0.coinId == id }) {
                return nil
            }

            let name = coin.name.trimmed()
            let symbol = coin.symbol.uppercased().trimmed()

            var items: [CoinModel.Item] = coin.networks.compactMap { network in
                guard let item = tokenItemMapper.mapToTokenItem(id: id, name: name, symbol: symbol, network: network) else {
                    return nil
                }

                return CoinModel.Item(id: id, tokenItem: item)
            }

            // add l2 networks
            if id == Blockchain.ethereum(testnet: false).coinId {
                let l2Items = l2Blockchains.map {
                    let tokenItm = TokenItem.blockchain(.init($0, derivationPath: nil))
                    return CoinModel.Item(id: id, tokenItem: tokenItm)
                }

                items.append(contentsOf: l2Items)
            }

            if items.isEmpty {
                return nil
            }

            return CoinModel(id: id, name: name, symbol: symbol, items: items)
        }
    }
}
