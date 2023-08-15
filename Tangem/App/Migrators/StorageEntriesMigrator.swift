//
//  StorageEntriesMigrator.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class StorageEntriesMigrator {
    typealias StorageWriter = (_ tokens: [StorageEntry.V3.Entry], _ cardID: String) -> Void

    private let persistanceStorage: PersistentStorageProtocol
    private let storageWriter: StorageWriter
    private let cardID: String

    init(
        persistanceStorage: PersistentStorageProtocol,
        storageWriter: @escaping StorageWriter,
        cardID: String
    ) {
        self.persistanceStorage = persistanceStorage
        self.storageWriter = storageWriter
        self.cardID = cardID
    }

    // MARK: - Common

    func migrate(
        from currentStorageVersion: StorageEntry.Version,
        to actualVersion: StorageEntry.Version
    ) {
        migrateIfNeeded(from: getCurrentStorageVersion(currentStorageVersion), to: actualVersion)
    }

    private func getCurrentStorageVersion(
        _ currentStorageVersionSinceV3: StorageEntry.Version
    ) -> StorageEntry.Version {
        // Storage versioning was introduced in v3, so we have to apply some heuristic for v1/v2 versions
        if getV1StorageEntries() != nil {
            return .v1
        }

        if getV2StorageEntries() != nil {
            return .v2
        }

        return currentStorageVersionSinceV3
    }

    private func migrateIfNeeded(
        from oldVersion: StorageEntry.Version,
        to newVersion: StorageEntry.Version
    ) {
        var wasMigrated = false

        switch oldVersion {
        case .v1:
            wasMigrated = migrateV1StorageEntriesIfNeeded()
        case .v2:
            wasMigrated = migrateV2StorageEntriesIfNeeded()
        case .v3:
            wasMigrated = migrateV3StorageEntriesIfNeeded()
        }

        if wasMigrated {
            AppLog.shared.debug(
                """
                "\(objectDescription(self)): successfully performed storage migration for cardID \
                \(cardID) from version \(oldVersion.rawValue) to \(newVersion.rawValue).
                """
            )
        } else {
            AppLog.shared.debug(
                """
                \(objectDescription(self)): storage migration for cardID \(cardID) from version \
                \(oldVersion.rawValue) to \(newVersion.rawValue) was requested, but not performed.
                """
            )
        }
    }

    // MARK: - V1 specific

    private func migrateV1StorageEntriesIfNeeded() -> Bool {
        guard let v1Wallets = getV1StorageEntries() else { return false }

        v1Wallets.forEach { cardId, v1StorageEntries in
            let blockchains = Set(v1StorageEntries.map { $0.blockchain })
            let tokens = v1StorageEntries.compactMap { $0.token }
            let groupedTokens = Dictionary(grouping: tokens, by: { $0.blockchain })

            let v2StorageEntries: [StorageEntry.V2.Entry] = blockchains.map { blockchain in
                let tokens = groupedTokens[blockchain]?.map { $0.newToken } ?? []
                let network = BlockchainNetwork(
                    blockchain,
                    derivationPath: blockchain.derivationPath(for: .v1)
                )
                return StorageEntry.V2.Entry(blockchainNetwork: network, tokens: tokens)
            }
            migrateV2StorageEntries(v2StorageEntries, forCardID: cardId)
        }

        return true
    }

    private func getV1StorageEntries() -> [String: [StorageEntry.V1.Entry]]? {
        return persistanceStorage.readAllWallets().nilIfEmpty
    }

    // MARK: - V2 specific

    private func migrateV2StorageEntriesIfNeeded() -> Bool {
        guard let storageEntries = getV2StorageEntries() else { return false }

        migrateV2StorageEntries(storageEntries, forCardID: cardID)

        return true
    }

    private func migrateV2StorageEntries(
        _ v2StorageEntries: [StorageEntry.V2.Entry],
        forCardID cardID: String
    ) {
        let v3StorageEntries: [StorageEntry.V3.Entry] = v2StorageEntries
            .reduce(into: []) { partialResult, element in
                let blockchainNetwork = element.blockchainNetwork
                let networkId = element.blockchainNetwork.blockchain.networkId
                partialResult.append(
                    StorageEntry.V3.Entry(
                        id: element.blockchainNetwork.blockchain.coinId,
                        networkId: networkId,
                        name: element.blockchainNetwork.blockchain.displayName,
                        symbol: element.blockchainNetwork.blockchain.currencySymbol,
                        decimals: element.blockchainNetwork.blockchain.decimalCount,
                        blockchainNetwork: blockchainNetwork,
                        contractAddress: nil
                    )
                )
                partialResult += element.tokens.map { token in
                    StorageEntry.V3.Entry(
                        id: token.id,
                        networkId: networkId,
                        name: token.name,
                        symbol: token.symbol,
                        decimals: token.decimalCount,
                        blockchainNetwork: blockchainNetwork,
                        contractAddress: token.contractAddress
                    )
                }
            }

        storageWriter(v3StorageEntries, cardID)
    }

    private func getV2StorageEntries() -> [StorageEntry.V2.Entry]? {
        let storageEntries: [StorageEntry.V2.Entry]? = try? persistanceStorage.value(for: .wallets(cid: cardID))

        return storageEntries?.nilIfEmpty
    }

    // MARK: - V3 specific

    private func migrateV3StorageEntriesIfNeeded() -> Bool {
        // No-op, actual version at the moment
        return false
    }
}
