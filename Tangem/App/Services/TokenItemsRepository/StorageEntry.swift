//
//  StorageEntry.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct StorageEntry: Hashable, Codable, Equatable {
    let blockchainNetwork: BlockchainNetwork
    var tokens: [Token]

    init(blockchainNetwork: BlockchainNetwork, tokens: [Token]) {
        self.blockchainNetwork = blockchainNetwork
        self.tokens = tokens
    }

    init(blockchainNetwork: BlockchainNetwork, token: Token?) {
        self.blockchainNetwork = blockchainNetwork

        if let token = token {
            tokens = [token]
        } else {
            tokens = []
        }
    }
}

extension StorageEntry {
    var walletModelIds: [Int] {
        let mainCoinId = WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id
        let tokenCoinIds = tokens.map {
            WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .token(value: $0)).id
        }
        return [mainCoinId] + tokenCoinIds
    }
}
