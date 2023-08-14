//
//  _TokenItemsRepository.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Improve naming
// TODO: Andrey Fedorov - version should be stored in a storage itself?
protocol _TokenItemsRepository {
    var isInitialized: Bool { get }

    func update(_ tokens: [StorageEntry.V3.Token])
    func append(_ tokens: [StorageEntry.V3.Token])
    func remove(_ blockchainNetworks: [StorageEntry.V3.BlockchainNetwork])
    func remove(_ tokens: [StorageEntry.V3.Token], in blockchainNetwork: BlockchainNetwork)
    func removeAll()

    func getItems() -> [StorageEntry.V3.Token]
}

final class _CommonTokenItemsRepository {
    @Injected(\.persistentStorage) var persistanceStorage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonTokenItemsRepository.lockQueue")
    private let key: String
    private var cache: [StorageEntry.V3.Token]?

    init(key: String) {
        self.key = key

        lockQueue.sync { /* migrate() */ } // from v1|v2 to v3
    }

    deinit {
        AppLog.shared.debug("\(#function) \(objectDescription(self))")
    }
}

// MARK: - TokenItemsRepository protocol conformance

extension _CommonTokenItemsRepository: _TokenItemsRepository {
    var isInitialized: Bool {
        lockQueue.sync {
            // Here it's necessary to distinguish between empty (`[]` value) and non-initialized
            // (`nil` value) storage, therefore direct access to the underlying storage is used here
            let entries: [StorageEntry.V3.Token]? = try? persistanceStorage.value(for: .wallets(cid: key))
            return entries != nil
        }
    }

    func update(_ tokens: [StorageEntry.V3.Token]) {
        lockQueue.sync {
            save(tokens, forCardID: key)
        }
    }

    func append(_ tokens: [StorageEntry.V3.Token]) {
        lockQueue.sync {
            var existingTokens = fetch(forCardID: key)
            var hasChanges = false
            var existingBlockchainNetworksToUpdate: [StorageEntry.V3.BlockchainNetwork] = []

            let existingTokensGroupedByBlockchainNetworks = Dictionary(
                grouping: existingTokens.enumerated(),
                by: \.element.blockchainNetwork
            )

            let newTokensGroupedByBlockchainNetworks = Dictionary(grouping: tokens, by: \.blockchainNetwork)
            let newBlockchainNetworks = tokens.unique(by: \.blockchainNetwork).map(\.blockchainNetwork)

            for newBlockchainNetwork in newBlockchainNetworks {
                if existingTokensGroupedByBlockchainNetworks[newBlockchainNetwork] != nil {
                    // This blockchain network already exists, and it probably needs to be updated with new tokens
                    existingBlockchainNetworksToUpdate.append(newBlockchainNetwork)
                } else if let newTokens = newTokensGroupedByBlockchainNetworks[newBlockchainNetwork] {
                    // New network, just appending all tokens from it to the end of the existing list
                    existingTokens.append(contentsOf: newTokens)
                    hasChanges = true
                }
            }

            for blockchainNetworkToUpdate in existingBlockchainNetworksToUpdate {
                guard
                    let existingTokensForBlockchainNetwork = existingTokensGroupedByBlockchainNetworks[blockchainNetworkToUpdate]?
                    .keyedFirst(by: \.element.contractAddress), // may contain `nil` key
                    let newTokensForBlockchainNetwork = newTokensGroupedByBlockchainNetworks[blockchainNetworkToUpdate]
                else {
                    continue
                }

                for newToken in newTokensForBlockchainNetwork {
                    if let (existingIndex, existingToken) = existingTokensForBlockchainNetwork[newToken.contractAddress] {
                        if existingToken.id == nil, newToken.id != nil {
                            // Token has been saved without id, just updating this token
                            existingTokens[existingIndex] = newToken
                            hasChanges = true
                        }
                    } else {
                        // Token hasn't been added yet, just appending it to the end of the existing list
                        existingTokens.append(newToken)
                        hasChanges = true
                    }
                }
            }

            if hasChanges {
                save(existingTokens, forCardID: key)
            }
        }
    }

    func remove(_ blockchainNetworks: [BlockchainNetwork]) {
        lockQueue.sync {
            let blockchainNetworks = blockchainNetworks.toSet()
            let existingItems = fetch(forCardID: key)
            var newItems = existingItems

            newItems.removeAll { blockchainNetworks.contains($0.blockchainNetwork) }

            let hasRemoved = newItems.count != existingItems.count
            if hasRemoved {
                save(newItems, forCardID: key)
            }
        }
    }

    func remove(_ tokens: [StorageEntry.V3.Token], in blockchainNetwork: BlockchainNetwork) {
        lockQueue.sync {
            let contractAddresses = tokens.map(\.contractAddress).toSet() // may contain `nil` element
            let existingItems = fetch(forCardID: key)
            var newItems = existingItems

            newItems.removeAll { $0.blockchainNetwork == blockchainNetwork && contractAddresses.contains($0.contractAddress) }

            let hasRemoved = newItems.count != existingItems.count
            if hasRemoved {
                save(newItems, forCardID: key)
            }
        }
    }

    func removeAll() {
        lockQueue.sync {
            save([], forCardID: key)
        }
    }

    func getItems() -> [StorageEntry.V3.Token] {
        lockQueue.sync {
            return fetch(forCardID: key)
        }
    }
}

// MARK: - Private

private extension _CommonTokenItemsRepository {
    func migrate() {
        // TODO: Andrey Fedorov - Add actual implementation

        /*
         let wallets: [String: [LegacyStorageEntry]] = persistanceStorage.readAllWallets()

         guard !wallets.isEmpty else {
             return
         }

         wallets.forEach { cardId, oldData in
             let blockchains = Set(oldData.map { $0.blockchain })
             let tokens = oldData.compactMap { $0.token }
             let groupedTokens = Dictionary(grouping: tokens, by: { $0.blockchain })

             let newData: [StorageEntry] = blockchains.map { blockchain in
                 let tokens = groupedTokens[blockchain]?.map { $0.newToken } ?? []
                 let network = BlockchainNetwork(
                     blockchain,
                     derivationPath: blockchain.derivationPath(for: .v1)
                 )
                 return StorageEntry(blockchainNetwork: network, tokens: tokens)
             }

             save(newData, for: cardId)
         }
          */
    }

    func fetch(forCardID cardID: String) -> [StorageEntry.V3.Token] {
        if let cachedItems = cache {
            return cachedItems
        }

        let tokens: [StorageEntry.V3.Token] = (try? persistanceStorage.value(for: .wallets(cid: cardID))) ?? []
        cache = tokens

        return tokens
    }

    func save(_ tokens: [StorageEntry.V3.Token], forCardID cardID: String) {
        markCacheAsDirty()

        do {
            try persistanceStorage.store(value: tokens, for: .wallets(cid: cardID))
        } catch {
            assertionFailure("\(objectDescription(self)) saving error: \(error)")
        }
    }

    func markCacheAsDirty() {
        cache = nil
    }
}
