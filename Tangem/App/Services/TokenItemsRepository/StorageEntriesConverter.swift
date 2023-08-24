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
    func convertToStorageEntry(
        _ blockchainNetwork: BlockchainNetwork
    ) -> StorageEntriesList.Entry {
        return StorageEntriesList.Entry(
            id: blockchainNetwork.blockchain.coinId,
            name: blockchainNetwork.blockchain.displayName,
            symbol: blockchainNetwork.blockchain.currencySymbol,
            decimalCount: blockchainNetwork.blockchain.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: nil
        )
    }

    func convertToStorageEntry(
        _ token: BlockchainSdk.Token,
        in blockchainNetwork: BlockchainNetwork
    ) -> StorageEntriesList.Entry {
        return StorageEntriesList.Entry(
            id: token.id,
            name: token.name,
            symbol: token.symbol,
            decimalCount: token.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: token.contractAddress
        )
    }

//    func convertToToken(
//        _ storageEntry: StorageEntry.V3.Entry
//    ) -> BlockchainSdk.Token? {
//        guard let contractAddress = storageEntry.contractAddress else { return nil }
//
//        return BlockchainSdk.Token(
//            name: storageEntry.name,
//            symbol: storageEntry.symbol,
//            contractAddress: contractAddress,
//            decimalCount: storageEntry.decimalCount,
//            id: storageEntry.id
//        )
//    }
//
//    func convertToBlockchainNetwork(
//        _ storageEntry: StorageEntry.V3.Entry
//    ) -> BlockchainNetwork? {
//        guard !storageEntry.isToken else { return nil }
//
//        return storageEntry.blockchainNetwork
//    }
}
