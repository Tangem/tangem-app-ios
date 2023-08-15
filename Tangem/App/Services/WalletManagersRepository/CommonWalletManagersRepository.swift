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

    private func update(with entries: [StorageEntry.V2.Entry], _ keys: [CardDTO.Wallet]) {
        var managers = walletManagers.value
        var hasUpdates = false

        for entry in entries {
            if let existingWalletManager = walletManagers.value[entry.blockchainNetwork] {
                let tokensToRemove = Set(existingWalletManager.cardTokens).subtracting(entry.tokens)
                for tokenToRemove in tokensToRemove {
                    existingWalletManager.removeToken(tokenToRemove)
                    hasUpdates = true
                }

                let tokensToAdd = Set(entry.tokens).subtracting(existingWalletManager.cardTokens)
                if !tokensToAdd.isEmpty {
                    existingWalletManager.addTokens(Array(tokensToAdd))
                    hasUpdates = true
                }

            } else if let newWalletManager = makeWalletManager(for: entry, keys) {
                managers[entry.blockchainNetwork] = newWalletManager
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

    private func makeWalletManager(for entry: StorageEntry.V2.Entry, _ keys: [CardDTO.Wallet]) -> WalletManager? {
        do {
            return try walletManagerFactory.makeWalletManager(for: entry, keys: keys)
        } catch AnyWalletManagerFactoryError.noDerivation {
            AppLog.shared.debug("‼️ No derivation for \(entry.blockchainNetwork.blockchain.displayName)")
        } catch {
            AppLog.shared.debug("‼️ Failed to create \(entry.blockchainNetwork.blockchain.displayName)")
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
