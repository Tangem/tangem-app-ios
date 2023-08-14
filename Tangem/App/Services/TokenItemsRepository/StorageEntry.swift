//
//  StorageEntry.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token // TODO: Andrey Fedorov - Remove this import if possible

// MARK: - V1

// TODO: Andrey Fedorov - Put `LegacyToken` and `LegacyCloudToken` here

// MARK: - V2

struct StorageEntry: Codable, Hashable { // TODO: Andrey Fedorov - Move into v2
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

// MARK: - V3

extension StorageEntry {
    enum Version: Codable {
        case v1
        case v2
        case v3
    }

    enum V3 {
        typealias BlockchainNetwork = Tangem.BlockchainNetwork

        enum Grouping: Codable {
            case none
            case byBlockchainNetwork
        }

        enum Sorting: Codable {
            case manual
            case byBalance
        }

        struct Token: Codable {
            let id: String?
            let networkId: String
            let name: String
            let symbol: String
            let decimals: Int
            let blockchainNetwork: BlockchainNetwork
            let contractAddress: String?
        }

        struct List: Codable {
            let version: Version
            let grouping: Grouping
            let sorting: Sorting
            let tokens: [Token]
        }
    }
}
