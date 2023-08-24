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
        // TODO: Andrey Fedorov - Add actual implementation
        /*
         lockQueue.sync {
             var items = fetch(for: key)
             var hasAppended: Bool = false

             entries.forEach {
                 if items.add(entry: $0) {
                     hasAppended = true
                 }
             }

             if hasAppended {
                 save(items, for: key)
             }
         }
          */
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

// MARK: - Private Array extension

private extension Array where Element == StorageEntry {
    mutating func add(entry: StorageEntry) -> Bool {
        guard let existingIndex = firstIndex(where: { $0.blockchainNetwork == entry.blockchainNetwork }) else {
            append(entry)
            return true
        }

        // We already have the blockchainNetwork in storage
        var appended = false

        // Add new tokens in the existing StorageEntry
        entry.tokens.forEach { token in
            if !self[existingIndex].tokens.contains(token) {
                // Token hasn't been append
                self[existingIndex].tokens.append(token)
                appended = true
            } else if let savedTokenIndex = self[existingIndex].tokens.firstIndex(of: token),
                      self[existingIndex].tokens[savedTokenIndex].id == nil,
                      token.id != nil {
                // Token has been saved without id. Just update this token
                self[existingIndex].tokens[savedTokenIndex] = token // upgrade custom token
                appended = true
            }
        }

        return appended
    }

    mutating func tryRemove(token: Token, in blockchainNetwork: BlockchainNetwork) -> Bool {
        if let existingIndex = firstIndex(where: { $0.blockchainNetwork == blockchainNetwork }) {
            if let tokenIndex = self[existingIndex].tokens.firstIndex(where: { $0 == token }) {
                self[existingIndex].tokens.remove(at: tokenIndex)
                return true
            }
        }

        return false
    }

    mutating func tryRemove(blockchainNetwork: BlockchainNetwork) -> Bool {
        if let existingIndex = firstIndex(where: { $0.blockchainNetwork == blockchainNetwork }) {
            remove(at: existingIndex)
            return true
        }

        return false
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
