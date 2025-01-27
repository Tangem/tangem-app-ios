//
//  StorageEntry.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

struct StorageEntry: Hashable {
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
    var walletModelIds: [WalletModel.ID] {
        let mainCoinId = WalletModel.Id(tokenItem: .blockchain(blockchainNetwork)).id
        let tokenCoinIds = tokens.map {
            WalletModel.Id(tokenItem: .token($0, blockchainNetwork)).id
        }
        return [mainCoinId] + tokenCoinIds
    }
}
