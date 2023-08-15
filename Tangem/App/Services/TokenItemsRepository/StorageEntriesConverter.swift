//
//  StorageEntriesConverter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

struct StorageEntriesConverter {
    func convert(
        _ blockchainNetwork: BlockchainNetwork
    ) -> StorageEntry.V3.Entry {
        return StorageEntry.V3.Entry(
            id: blockchainNetwork.blockchain.coinId,    // TODO: Andrey Fedorov - can `blockchainNetwork.blockchain.coinId` be used here?
            networkId: blockchainNetwork.blockchain.networkId,
            name: blockchainNetwork.blockchain.displayName,
            symbol: blockchainNetwork.blockchain.currencySymbol,
            decimals: blockchainNetwork.blockchain.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: nil
        )
    }

    func convert(
        _ token: BlockchainSdk.Token,
        in blockchainNetwork: BlockchainNetwork
    ) -> StorageEntry.V3.Entry {
        return StorageEntry.V3.Entry(
            id: token.id,
            networkId: blockchainNetwork.blockchain.networkId,
            name: token.name,
            symbol: token.symbol,
            decimals: token.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: token.contractAddress
        )
    }

    func convert(
        _ storageEntry: StorageEntry.V3.Entry
    ) -> BlockchainSdk.Token? {
        guard let contractAddress = storageEntry.contractAddress else { return nil }

        return BlockchainSdk.Token(
            name: storageEntry.name,
            symbol: storageEntry.symbol,
            contractAddress: contractAddress,
            decimalCount: storageEntry.decimals,
            id: storageEntry.id
        )
    }

    func convert(
        _ storageEntry: StorageEntry.V3.Entry
    ) -> BlockchainNetwork? {
        guard storageEntry.contractAddress == nil else { return nil }

        return storageEntry.blockchainNetwork
    }
}
