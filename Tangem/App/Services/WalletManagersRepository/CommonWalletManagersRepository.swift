//
//  CommonWalletManagersRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonWalletManagersRepository {
    // MARK: - Dependencies

    private let keysProvider: KeysProvider
    private let userTokenListManager: UserTokenListManager
    private let walletManagerFactory: AnyWalletManagerFactory

    private var walletManagers = CurrentValueSubject<[BlockchainNetwork: WalletManager], Never>([:])
    private var bag = Set<AnyCancellable>()

    init(
        keysProvider: KeysProvider,
        userTokenListManager: UserTokenListManager,
        walletManagerFactory: AnyWalletManagerFactory
    ) {
        self.keysProvider = keysProvider
        self.userTokenListManager = userTokenListManager
        self.walletManagerFactory = walletManagerFactory
        bind()
    }

    private func bind() {
        userTokenListManager.userTokensPublisher
            .combineLatest(keysProvider.keysPublisher)
            .sink { [weak self] entries, keys in
                self?.update(with: entries, keys)
            }
            .store(in: &bag)
    }

    private func update(with entries: [StorageEntry.V3.Entry], _ keys: [CardDTO.Wallet]) {
        let entriesGroupedByBlockchainNetwork = Dictionary(grouping: entries, by: \.blockchainNetwork)
        let converter = StorageEntriesConverter()
        var managers = walletManagers.value
        var hasUpdates = false

        for (blockchainNetwork, entriesForBlockchainNetwork) in entriesGroupedByBlockchainNetwork {
            let tokensForBlockchainNetwork = entriesForBlockchainNetwork.compactMap(converter.convertToToken(_:))

            if let existingWalletManager = walletManagers.value[blockchainNetwork] {
                let tokensToRemove = Set(existingWalletManager.cardTokens).subtracting(tokensForBlockchainNetwork)
                for tokenToRemove in tokensToRemove {
                    existingWalletManager.removeToken(tokenToRemove)
                    hasUpdates = true
                }

                let tokensToAdd = Set(tokensForBlockchainNetwork).subtracting(existingWalletManager.cardTokens)
                if !tokensToAdd.isEmpty {
                    existingWalletManager.addTokens(Array(tokensToAdd))
                    hasUpdates = true
                }

            } else if let newWalletManager = makeWalletManager(
                tokens: tokensForBlockchainNetwork,
                blockchainNetwork: blockchainNetwork,
                keys: keys
            ) {
                managers[blockchainNetwork] = newWalletManager
                hasUpdates = true
            }
        }

        let actualNetworks = Set(entries.map { $0.blockchainNetwork })
        let currentNetworks = Set(managers.keys)
        let networksToDelete = currentNetworks.subtracting(actualNetworks)

        if !networksToDelete.isEmpty {
            networksToDelete.forEach {
                managers[$0] = nil
            }
            hasUpdates = true
        }

        if hasUpdates {
            walletManagers.send(managers)
        }
    }

    private func makeWalletManager(
        tokens: [BlockchainSdk.Token],
        blockchainNetwork: BlockchainNetwork,
        keys: [CardDTO.Wallet]
    ) -> WalletManager? {
        do {
            return try walletManagerFactory.makeWalletManager(
                tokens: tokens,
                blockchainNetwork: blockchainNetwork,
                keys: keys
            )
        } catch AnyWalletManagerFactoryError.noDerivation {
            AppLog.shared.debug("‼️ No derivation for \(blockchainNetwork.blockchain.displayName)")
        } catch {
            AppLog.shared.debug("‼️ Failed to create \(blockchainNetwork.blockchain.displayName)")
            AppLog.shared.error(error)
        }

        return nil
    }
}

extension CommonWalletManagersRepository: WalletManagersRepository {
    var signatureCountValidator: SignatureCountValidator? {
        walletManagers.value.values.first as? SignatureCountValidator
    }

    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: any WalletManager], Never> {
        walletManagers.eraseToAnyPublisher()
    }
}
