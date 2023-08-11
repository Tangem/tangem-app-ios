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

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    func mapToCoinModels(_ response: CoinsList.Response) -> [CoinModel] {
        response.coins.map { coin in
            let id = coin.id.trimmed()
            let name = coin.name.trimmed()
            let symbol = coin.symbol.uppercased().trimmed()

            let items: [TokenItem] = coin.networks.compactMap { network in
                // We should find and use a exactly same blockchain that in the supportedBlockchains set
                guard let blockchain = supportedBlockchains[network.networkId] else {
                    return nil
                }

                guard let contractAddress = network.contractAddress,
                      let decimalCount = network.decimalCount else {
                    return .blockchain(blockchain)
                }

                let token = Token(
                    name: name,
                    symbol: symbol,
                    contractAddress: contractAddress.trimmed(),
                    decimalCount: decimalCount,
                    id: id,
                    exchangeable: network.exchangeable
                )

                return .token(token, blockchain)
            }

            return CoinModel(id: id, name: name, symbol: symbol, items: items)
        }
    }
}
