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
        AppLog.shared.debug("\(#function) \(objectDescription(self))")
    }
}

// MARK: - TokenItemsRepository protocol conformance

extension CommonTokenItemsRepository: TokenItemsRepository {
    var containsFile: Bool {
        lockQueue.sync {
            let list: StorageEntriesList? = try? persistanceStorage.value(for: .wallets(cid: key))
            return list != nil
        }
    }

    func update(_ list: StorageEntriesList) {
        lockQueue.sync {
            save(list)
        }
    }

    func append(_ entries: [StorageEntriesList.Entry]) {
        lockQueue.sync {
            var hasChanges = false
            let existingList = fetch()
            var existingEntries = existingList.entries

            var existingBlockchainNetworksToUpdate: [BlockchainNetwork] = []
            let existingBlockchainNetworks = existingEntries
                .map(\.blockchainNetwork)
                .toSet()

            let newEntriesGroupedByBlockchainNetworks = Dictionary(grouping: entries, by: \.blockchainNetwork)
            let newBlockchainNetworks = entries.unique(by: \.blockchainNetwork).map(\.blockchainNetwork)

            for newBlockchainNetwork in newBlockchainNetworks {
                if existingBlockchainNetworks.contains(newBlockchainNetwork) {
                    // This blockchain network already exists, and it probably needs to be updated with new tokens
                    existingBlockchainNetworksToUpdate.append(newBlockchainNetwork)
                } else if let newEntries = newEntriesGroupedByBlockchainNetworks[newBlockchainNetwork] {
                    // New blockchain network, just appending all entries from it to the end of the existing list
                    existingEntries.append(contentsOf: newEntries)
                    hasChanges = true
                }
            }

            for blockchainNetwork in existingBlockchainNetworksToUpdate {
                guard let newEntriesForBlockchainNetwork = newEntriesGroupedByBlockchainNetworks[blockchainNetwork] else {
                    continue
                }

                for newEntry in newEntriesForBlockchainNetwork {
                    // We already have this network, so only tokens are gonna be added
                    guard newEntry.isToken else { continue }

                    if let index = existingEntries.firstIndex(where: { entry in
                        return entry.blockchainNetwork == blockchainNetwork && entry.contractAddress == newEntry.contractAddress
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
                let editedList = StorageEntriesList(
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
            let blockchainNetworksToRemove = blockchainNetworks.toSet()
            let existingList = fetch()
            let existingEntries = existingList.entries
            var editedEntries = existingEntries

            editedEntries.removeAll { blockchainNetworksToRemove.contains($0.blockchainNetwork) }

            let hasRemoved = editedEntries.count != existingEntries.count
            if hasRemoved {
                let editedList = StorageEntriesList(
                    entries: editedEntries,
                    grouping: existingList.grouping,
                    sorting: existingList.sorting
                )
                save(editedList)
            }
        }
    }

    func remove(_ entries: [StorageEntriesList.Entry]) {
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
                let editedList = StorageEntriesList(
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

    func getList() -> StorageEntriesList {
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

        let converter = StorageEntriesConverter()
        let convertedStorageEntries: [StorageEntriesList.Entry] = legacyStorageEntries
            .reduce(into: []) { partialResult, element in
                let blockchainNetwork = element.blockchainNetwork

                partialResult.append(converter.convertToStorageEntry(blockchainNetwork))
                partialResult += element.tokens.map { converter.convertToStorageEntry($0, in: blockchainNetwork) }
            }

        let storageEntriesList = StorageEntriesList(
            entries: convertedStorageEntries,
            grouping: StorageEntriesList.empty.grouping,
            sorting: StorageEntriesList.empty.sorting
        )
        save(storageEntriesList)
    }

    func fetch() -> StorageEntriesList {
        return (try? persistanceStorage.value(for: .wallets(cid: key))) ?? .empty
    }

    func save(_ items: StorageEntriesList) {
        do {
            try persistanceStorage.store(value: items, for: .wallets(cid: key))
        } catch {
            assertionFailure("TokenItemsRepository saving error \(error)")
        }
    }
}

// MARK: - Convenience extensions

private extension StorageEntriesList {
    static var empty: Self { Self(entries: [], grouping: .none, sorting: .manual) }
}

// MARK: - Legacy storage

/// Same as `StorageEntry`.
private struct LegacyStorageEntry: Decodable, Hashable {
    let blockchainNetwork: BlockchainNetwork
    let tokens: [BlockchainSdk.Token]
}

// MARK: - Auxiliary types

private extension CommonTokenItemsRepository {
    /// A key for fast O(1) lookups in sets, dictionaries, etc.
    struct StorageEntryKey: Hashable {
        let blockchainNetwork: BlockchainNetwork
        let contractAddresses: String?
    }
}
