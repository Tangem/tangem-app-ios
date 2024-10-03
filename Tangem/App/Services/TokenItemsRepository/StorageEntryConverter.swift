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
    // MARK: - StoredUserTokenList.Entry to StorageEntry

    func convertToStorageEntries(_ userTokens: [StoredUserTokenList.Entry]) -> [StorageEntry] {
        let userTokensGroupedByBlockchainNetworks = userTokens
            .grouped(by: \.blockchainNetwork)

        let blockchainNetworks = userTokens
            .filter { !$0.isToken }
            .uniqueProperties(\.blockchainNetwork)

        return blockchainNetworks.reduce(into: []) { partialResult, blockchainNetwork in
            let userTokens = userTokensGroupedByBlockchainNetworks[blockchainNetwork] ?? []
            let tokens = userTokens.compactMap(convertToToken(_:))
            let storageEntry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: tokens)
            partialResult.append(storageEntry)
        }
    }

    func convertToToken(_ userToken: StoredUserTokenList.Entry) -> Token? {
        guard let contractAddress = userToken.contractAddress else { return nil }

        return Token(
            name: userToken.name,
            symbol: userToken.symbol,
            contractAddress: contractAddress,
            decimalCount: userToken.decimalCount,
            id: userToken.id
        )
    }

    // MARK: - StorageEntry to StoredUserTokenList.Entry

    func convertToStoredUserTokens(_ entries: [StorageEntry]) -> [StoredUserTokenList.Entry] {
        return entries.reduce(into: []) { partialResult, entry in
            let blockchainNetwork = entry.blockchainNetwork
            let blockchain = blockchainNetwork.blockchain

            partialResult.append(
                StoredUserTokenList.Entry(
                    id: blockchain.coinId,
                    name: blockchain.displayName,
                    symbol: blockchain.currencySymbol,
                    decimalCount: blockchain.decimalCount,
                    blockchainNetwork: blockchainNetwork,
                    contractAddress: nil
                )
            )

            partialResult += entry.tokens.map { convertToStoredUserToken($0, in: blockchainNetwork) }
        }.unique()
    }

    func convertToStoredUserToken(
        _ token: Token,
        in blockchainNetwork: BlockchainNetwork
    ) -> StoredUserTokenList.Entry {
        return StoredUserTokenList.Entry(
            id: token.id,
            name: token.name,
            symbol: token.symbol,
            decimalCount: token.decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: token.contractAddress
        )
    }

    // MARK: - StorageEntry to TokenItem

    func convertToTokenItem(_ entries: [StoredUserTokenList.Entry]) -> [TokenItem] {
        entries.map {
            guard let contractAddress = $0.contractAddress else {
                return .blockchain($0.blockchainNetwork)
            }

            let token = Token(
                name: $0.name,
                symbol: $0.symbol,
                contractAddress: contractAddress,
                decimalCount: $0.decimalCount,
                id: $0.id
            )
            return .token(token, $0.blockchainNetwork)
        }
    }

    func convertToTokenItems(_ entries: [StorageEntry]) -> [TokenItem] {
        entries.flatMap { entry in
            let blockchainToken = TokenItem.blockchain(entry.blockchainNetwork)
            let tokens = entry.tokens.map {
                TokenItem.token($0, entry.blockchainNetwork)
            }

            return [blockchainToken] + tokens
        }
    }
}
