//
//  StorageEntry.V2.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

extension StorageEntry {
    enum V2 {
        struct Entry: Codable, Hashable {
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
    }
}
