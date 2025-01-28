//
//  CommonTokenItemsRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

class CommonTokenItemsRepository {
    @Injected(\.persistentStorage) var persistanceStorage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonTokenItemsRepository.lockQueue")
    private let key: String

    init(key: String) {
        self.key = key

        lockQueue.sync { migrate() }
    }

    deinit {
        AppLog.debug(self)
    }
}

// MARK: - TokenItemsRepository

extension CommonTokenItemsRepository: TokenItemsRepository {
    var containsFile: Bool {
        lockQueue.sync {
            let list: StoredUserTokenList? = try? persistanceStorage.value(for: .wallets(cid: key))
            return list != nil
        }
    }

    func update(_ list: StoredUserTokenList) {
        lockQueue.sync {
            save(list)
        }
    }

    func append(_ entries: [StoredUserTokenList.Entry]) {
        lockQueue.sync {
            var hasChanges = false
            let existingList = fetch()
            var existingEntries = existingList.entries

            var existingNetworksToUpdate: [BlockchainNetwork] = []
            let existingNetworks = existingEntries.map(\.blockchainNetwork).toSet()

            let newEntriesGroupedByNetworks = entries.grouped(by: \.blockchainNetwork)
            let newNetworks = entries.uniqueProperties(\.blockchainNetwork)

            for network in newNetworks {
                if existingNetworks.contains(network) {
                    // This blockchain network already exists, and it probably needs to be updated with new tokens
                    existingNetworksToUpdate.append(network)
                } else if let newEntries = newEntriesGroupedByNetworks[network] {
                    // New blockchain network, just appending all entries from it to the end of the existing list
                    existingEntries.append(contentsOf: newEntries)
                    hasChanges = true
                }
            }

            for network in existingNetworksToUpdate {
                guard let newEntriesForBlockchainNetwork = newEntriesGroupedByNetworks[network] else {
                    continue
                }

                for newEntry in newEntriesForBlockchainNetwork {
                    // We already have this network, so only tokens are gonna be added
                    guard newEntry.isToken else { continue }

                    if let index = existingEntries.firstIndex(where: { entry in
                        return entry.blockchainNetwork == network && entry.contractAddress == newEntry.contractAddress
                    }) {
                        if existingEntries[index].id == nil, newEntry.id != nil {
                            // Entry has been saved without id, just updating this entry
                            existingEntries[index] = newEntry // upgrading custom token
                            hasChanges = true
                        }
                    } else {
                        // Token hasn't been added yet, just appending it to the end of the existing list
                        existingEntries.append(newEntry)
                        hasChanges = true
                    }
                }
            }

            if hasChanges {
                let editedList = StoredUserTokenList(
                    entries: existingEntries,
                    grouping: existingList.grouping,
                    sorting: existingList.sorting
                )
                save(editedList)
            }
        }
    }

    func remove(_ blockchainNetworks: [BlockchainNetwork]) {
        lockQueue.sync {
            let networksToRemove = blockchainNetworks.toSet()
            let existingList = fetch()
            let existingEntries = existingList.entries
            var editedEntries = existingEntries

            editedEntries.removeAll { networksToRemove.contains($0.blockchainNetwork) }

            let hasRemoved = editedEntries.count != existingEntries.count
            if hasRemoved {
                let editedList = StoredUserTokenList(
                    entries: editedEntries,
                    grouping: existingList.grouping,
                    sorting: existingList.sorting
                )
                save(editedList)
            }
        }
    }

    func remove(_ entries: [StoredUserTokenList.Entry]) {
        lockQueue.sync {
            let deletedEntriesKeys = entries
                .map { StorageEntryKey(blockchainNetwork: $0.blockchainNetwork, contractAddresses: $0.contractAddress) }
                .toSet()

            let existingList = fetch()
            let existingEntries = existingList.entries
            var editedEntries = existingEntries

            editedEntries.removeAll { entry in
                let key = StorageEntryKey(blockchainNetwork: entry.blockchainNetwork, contractAddresses: entry.contractAddress)
                return deletedEntriesKeys.contains(key)
            }

            let hasRemoved = editedEntries.count != existingEntries.count
            if hasRemoved {
                let editedList = StoredUserTokenList(
                    entries: editedEntries,
                    grouping: existingList.grouping,
                    sorting: existingList.sorting
                )
                save(editedList)
            }
        }
    }

    func removeAll() {
        lockQueue.sync {
            save(.empty)
        }
    }

    func getList() -> StoredUserTokenList {
        lockQueue.sync {
            return fetch()
        }
    }
}

// MARK: - Private

private extension CommonTokenItemsRepository {
    func migrate() {
        let legacyStorageEntries: [LegacyStorageEntry]? = try? persistanceStorage.value(for: .wallets(cid: key))

        guard let legacyStorageEntries = legacyStorageEntries?.nilIfEmpty else { return }

        let converter = LegacyStorageEntriesConverter()
        let convertedStorageEntries: [StoredUserTokenList.Entry] = legacyStorageEntries
            .reduce(into: []) { partialResult, element in
                let blockchainNetwork = element.blockchainNetwork

                partialResult.append(converter.convertToStorageEntry(blockchainNetwork))
                partialResult += element.tokens.map { converter.convertToStorageEntry($0, in: blockchainNetwork) }
            }
        let storageEntriesList = StoredUserTokenList(
            entries: convertedStorageEntries,
            grouping: StoredUserTokenList.empty.grouping,
            sorting: StoredUserTokenList.empty.sorting
        )

        save(storageEntriesList)
    }

    func fetch() -> StoredUserTokenList {
        return (try? persistanceStorage.value(for: .wallets(cid: key))) ?? .empty
    }

    func save(_ items: StoredUserTokenList) {
        do {
            try persistanceStorage.store(value: items, for: .wallets(cid: key))
        } catch {
            assertionFailure("TokenItemsRepository saving error \(error)")
        }
    }
}

// MARK: - Legacy storage

/// Same as `StorageEntry`.
private struct LegacyStorageEntry: Decodable, Hashable {
    let blockchainNetwork: BlockchainNetwork
    let tokens: [BlockchainSdk.Token]
}

private struct LegacyStorageEntriesConverter {
    func convertToStorageEntry(
        _ blockchainNetwork: BlockchainNetwork
    ) -> StoredUserTokenList.Entry {
        return StoredUserTokenList.Entry(
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
}

// MARK: - Auxiliary types

private extension CommonTokenItemsRepository {
    /// A key for fast O(1) lookups in sets, dictionaries, etc.
    struct StorageEntryKey: Hashable {
        let blockchainNetwork: BlockchainNetwork
        let contractAddresses: String?
    }
}
