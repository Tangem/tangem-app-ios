//
//  StorageEntryConverter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

struct StorageEntryConverter {
    // MARK: - StoredUserTokenList to StorageEntry

    func convertToStorageEntries(_ userTokens: [StoredUserTokenList.Entry]) -> [StorageEntry] {
        let userTokensGroupedByBlockchainNetworks = Dictionary(grouping: userTokens, by: \.blockchainNetwork)

        let blockchainNetworks = userTokens
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)

        return blockchainNetworks.reduce(into: []) { partialResult, blockchainNetwork in
            let userTokens = userTokensGroupedByBlockchainNetworks[blockchainNetwork] ?? []
            let tokens = convertToTokens(userTokens)
            let storageEntry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: tokens)
            partialResult.append(storageEntry)
        }
    }

    private func convertToTokens(_ userTokens: [StoredUserTokenList.Entry]) -> [Token] {
        return userTokens.compactMap { userToken in
            guard let contractAddress = userToken.contractAddress else { return nil }

            return Token(
                name: userToken.name,
                symbol: userToken.symbol,
                contractAddress: contractAddress,
                decimalCount: userToken.decimalCount,
                id: userToken.id
            )
        }
    }

    // MARK: - StorageEntry to StoredUserTokenList

    func convertToStoredUserTokens(_ entries: [StorageEntry]) -> [StoredUserTokenList.Entry] {
        return entries.reduce(into: []) { partialResult, entry in
            let blockchainNetwork = entry.blockchainNetwork
            let blockchain = blockchainNetwork.blockchain

            partialResult.append(
                StoredUserTokenList.Entry(
                    id: blockchain.coinId,
                    name: blockchain.displayName, // TODO: Andrey Fedorov - Is `displayName` valid here?
                    symbol: blockchain.currencySymbol,
                    decimalCount: blockchain.decimalCount,
                    blockchainNetwork: blockchainNetwork,
                    contractAddress: nil
                )
            )

            partialResult += convertToStoredUserTokens(entry.tokens, in: blockchainNetwork)
        }
    }

    func convertToStoredUserTokens(
        _ tokens: [Token],
        in blockchainNetwork: BlockchainNetwork
    ) -> [StoredUserTokenList.Entry] {
        return tokens.map { token in
            StoredUserTokenList.Entry(
                id: token.id,
                name: token.name,
                symbol: token.symbol,
                decimalCount: token.decimalCount,
                blockchainNetwork: blockchainNetwork,
                contractAddress: token.contractAddress
            )
        }
    }
}
