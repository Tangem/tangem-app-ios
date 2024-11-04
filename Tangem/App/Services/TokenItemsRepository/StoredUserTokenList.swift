//
//  StoredUserTokenList.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct StoredUserTokenList: Codable, Equatable {
    enum Grouping: Codable, Equatable {
        case none
        case byBlockchainNetwork
    }

    enum Sorting: Codable, Equatable {
        case manual
        case byBalance
    }

    struct Entry: Codable, Hashable {
        let id: String?
        let name: String
        let symbol: String
        let decimalCount: Int
        let blockchainNetwork: BlockchainNetwork
        let contractAddress: String?

        var coinId: String? {
            contractAddress == nil ? blockchainNetwork.blockchain.coinId : id
        }
    }

    let entries: [Entry]
    let grouping: Grouping
    let sorting: Sorting
}

// MARK: - Convenience extensions

extension StoredUserTokenList {
    static var empty: Self { Self(entries: [], grouping: .none, sorting: .manual) }
}

extension StoredUserTokenList.Entry {
    var isToken: Bool { contractAddress != nil }

    var isCustom: Bool { id == nil }

    var walletModelId: WalletModel.ID {
        let converter = StorageEntryConverter()

        if let token = converter.convertToToken(self) {
            return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .token(value: token)).id
        }

        return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id
    }
}
