//
//  CommonTokenItemsRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CommonTokenItemsRepository {
    @Injected(\.persistentStorage) var persistanceStorage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "token_items_repo_queue")
    private let key: String

    init(key: String) {
        self.key = key

        lockQueue.sync { migrate() }
    }

    deinit {
        AppLog.shared.debug("TokenItemsRepository deinit")
    }
}

// MARK: - TokenItemsRepository

extension CommonTokenItemsRepository: TokenItemsRepository {
    var containsFile: Bool {
        let entries: [StorageEntry]? = try? persistanceStorage.value(for: .wallets(cid: key))
        return entries != nil
    }

    func update(_ entries: [StorageEntry]) {
        lockQueue.sync {
            save(entries, for: key)
        }
    }

    func append(_ entries: [StorageEntry]) {
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
    }

    func remove(_ blockchainNetworks: [BlockchainNetwork]) {
        lockQueue.sync {
            var items = fetch(for: key)
            var hasRemoved: Bool = false

            blockchainNetworks.forEach {
                if items.tryRemove(blockchainNetwork: $0) {
                    hasRemoved = true
                }
            }

            if hasRemoved {
                save(items, for: key)
            }
        }
    }

    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork) {
        lockQueue.sync {
            var items = fetch(for: key)
            var hasRemoved: Bool = false

            tokens.forEach {
                if items.tryRemove(token: $0, in: blockchainNetwork) {
                    hasRemoved = true
                }
            }

            if hasRemoved {
                save(items, for: key)
            }
        }
    }

    func removeAll() {
        lockQueue.sync {
            save([], for: key)
        }
    }

    func getItems() -> [StorageEntry] {
        lockQueue.sync {
            return fetch(for: key)
        }
    }
}

// MARK: - Private

private extension CommonTokenItemsRepository {
    func migrate() {
        let wallets: [String: [StorageEntry.V1.Entry]] = persistanceStorage.readAllWallets()

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
    }

    func fetch(for cardId: String) -> [StorageEntry] {
        return (try? persistanceStorage.value(for: .wallets(cid: cardId))) ?? []
    }

    func save(_ items: [StorageEntry], for cardId: String) {
        do {
            try persistanceStorage.store(value: items, for: .wallets(cid: cardId))
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
