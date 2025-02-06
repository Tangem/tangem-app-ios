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

    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

    private let keysProvider: KeysProvider
    private let userTokenListManager: UserTokenListManager
    private let walletManagerFactory: AnyWalletManagerFactory

    /// We need to keep optional dictionary to track state when wallet managers dictionary wasn't able to initialize
    /// This state can happen while app awaiting API list from server, because Wallet managers can't be created without this info
    /// Nil state is not the same as an empty state, because user can remove all tokens from main and the dictionary will be empty
    private var walletManagers = CurrentValueSubject<[BlockchainNetwork: WalletManager]?, Never>(nil)
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
        Publishers.CombineLatest3(
            userTokenListManager.userTokensPublisher,
            keysProvider.keysPublisher,
            apiListProvider.apiListPublisher
        )
        .sink { [weak self] entries, keys, apiList in
            self?.update(with: entries, keys, apiList: apiList)
        }
        .store(in: &bag)
    }

    private func update(with entries: [StorageEntry], _ keys: [CardDTO.Wallet], apiList: APIList) {
        var managers = walletManagers.value ?? [:]
        var hasUpdates = false

        for entry in entries {
            if let existingWalletManager = walletManagers.value?[entry.blockchainNetwork] {
                let tokensToRemove = Set(existingWalletManager.cardTokens).subtracting(entry.tokens)
                for tokenToRemove in tokensToRemove {
                    existingWalletManager.removeToken(tokenToRemove)
                    hasUpdates = true
                }

                let tokensToAdd = Set(entry.tokens).subtracting(existingWalletManager.cardTokens)
                if !tokensToAdd.isEmpty {
                    existingWalletManager.addTokens(Array(tokensToAdd))
                    // We need to reset lastUpdateTime to be able to load token info, if tokens added one by one sequentially.
                    // Otherwise balances on main will be displayed as dashes
                    existingWalletManager.setNeedsUpdate()
                    hasUpdates = true
                }

            } else if let newWalletManager = makeWalletManager(for: entry, keys, apiList: apiList) {
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

        if walletManagers.value == nil {
            // Emit initial list. Case with first card scan without derivations
            hasUpdates = true
        }

        if hasUpdates {
            walletManagers.send(managers)
        }
    }

    private func makeWalletManager(for entry: StorageEntry, _ keys: [CardDTO.Wallet], apiList: APIList) -> WalletManager? {
        do {
            return try walletManagerFactory.makeWalletManager(for: entry, keys: keys, apiList: apiList)
        } catch AnyWalletManagerFactoryError.noDerivation {
            AppLogger.warning("‼️ No derivation for \(entry.blockchainNetwork.blockchain.displayName)")
        } catch {
            AppLogger.error("‼️ Failed to create \(entry.blockchainNetwork.blockchain.displayName)", error: error)
        }

        return nil
    }
}

extension CommonWalletManagersRepository: WalletManagersRepository {
    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: any WalletManager], Never> {
        walletManagers
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
