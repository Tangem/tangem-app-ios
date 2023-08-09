//
//  TokenItemsRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenItemsRepository {
    var containsFile: Bool { get }

    func update(_ entries: [StorageEntry])
    func append(_ entries: [StorageEntry])

    func remove(_ blockchainNetworks: [BlockchainNetwork])
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork)
    func removeAll()

    func getItems() -> [StorageEntry]
}

extension TokenItemsRepository {
    func append(_ blockchainNetworks: [BlockchainNetwork]) {
        let entries = blockchainNetworks.map { StorageEntry(blockchainNetwork: $0, tokens: []) }
        append(entries)
    }

    func append(_ tokens: [Token], blockchainNetwork: BlockchainNetwork) {
        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: tokens)
        append([entry])
    }
}
