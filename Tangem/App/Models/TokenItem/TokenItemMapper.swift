//
//  TokenItemMapper.swift
//  Tangem
//
//  Created by skibinalexander on 03.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenItemMapper {
    let supportedBlockchains: Set<Blockchain>

    func mapToTokenItem(id: String, name: String, symbol: String, network: NetworkModel) -> TokenItem? {
        // We should find and use a exactly same blockchain that in the supportedBlockchains set
        guard let blockchain = supportedBlockchains[network.networkId] else {
            return nil
        }

        guard let contractAddress = network.contractAddress,
              let decimalCount = network.decimalCount else {
            return .blockchain(.init(blockchain, derivationPath: nil))
        }

        guard blockchain.canHandleTokens else {
            return nil
        }

        let token = Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress.trimmed(),
            decimalCount: decimalCount,
            id: id
        )

        return .token(token, .init(blockchain, derivationPath: nil))
    }
}
