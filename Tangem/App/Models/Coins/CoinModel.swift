//
//  CoinModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 16.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

struct CoinModel {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let items: [TokenItem]
}

extension CoinModel {
    init(with entity: CoinsResponse.Coin, baseImageURL: URL?) {
        let id = entity.id.trimmed()
        let name = entity.name.trimmed()
        let symbol = entity.symbol.uppercased().trimmed()
        let url = baseImageURL?.appendingPathComponent("large")
            .appendingPathComponent("\(id).png")

        items = entity.networks.compactMap { network in
            guard let blockchain = Blockchain(from: network.networkId) else {
                return nil
            }

            if let contractAddress = network.contractAddress, let decimalCount = network.decimalCount {
                return .token(Token(
                    name: name,
                    symbol: symbol,
                    contractAddress: contractAddress.trimmed(),
                    decimalCount: decimalCount,
                    id: id,
                    exchangeable: network.exchangeable
                ), blockchain)
            } else {
                return .blockchain(blockchain)
            }
        }

        self.id = id
        self.name = name
        self.symbol = symbol
        imageURL = url
    }
}
