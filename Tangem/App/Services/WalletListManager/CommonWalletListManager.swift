//
//  CommonWalletListManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

class CommonWalletListManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var config: UserWalletConfig
    private let userTokenListManager: UserTokenListManager

    /// Bool flag for migration custom token to token form our API
    private var migrated = false
    private var walletModels = CurrentValueSubject<[WalletModel], Never>([])
    private var entriesWithoutDerivation = CurrentValueSubject<[StorageEntry], Never>([])

    init(config: UserWalletConfig, userTokenListManager: UserTokenListManager) {
        self.config = config
        self.userTokenListManager = userTokenListManager
    }
}

// MARK: - WalletListManager

extension CommonWalletListManager: WalletListManager {
    func update(config: UserWalletConfig) {
        self.config = config
    }

    func getWalletModels() -> [WalletModel] {
        walletModels.value
    }

    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletModels.eraseToAnyPublisher()
    }

    func getEntriesWithoutDerivation() -> [StorageEntry] {
        entriesWithoutDerivation.value
    }

    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> {
        entriesWithoutDerivation.eraseToAnyPublisher()
    }

    func updateWalletModels() {
        AppLog.shared.debug("🔄 Updating Wallet models")

        var walletModels = getWalletModels()
        let entries = userTokenListManager.getEntriesFromRepository()
        log(entires: entries)

        var entriesToAdd: [StorageEntry] = []

        // Update tokens
        entries.forEach { entry in
            if let walletModel = walletModels.first(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                entry.tokens.forEach { token in
                    if !walletModel.getTokens().contains(token) {
                        walletModel.addTokens(entry.tokens)
                    }
                }

                walletModel.getTokens().forEach { token in
                    if !entry.tokens.contains(token) {
                        walletModel.removeToken(token)
                    }
                }
            } else {
                entriesToAdd.append(entry)
            }
        }

        if !config.hasFeature(.hdWallets) { // hotfix, do not remove
            entriesToAdd.removeAll(where: { $0.blockchainNetwork.derivationPath != nil })
        }

        var nonDeriveEntries: [StorageEntry] = []

        let walletModelsToAdd = entriesToAdd
            .compactMap { entry in
                let displayName = entry.blockchainNetwork.blockchain.displayName

                do {
                    let walletModel = try config.makeWalletModel(for: entry)
                    AppLog.shared.debug("✅ Make WalletModel for \(displayName) success")
                    return walletModel
                } catch WalletModelFactory.Errors.noDerivation {
                    AppLog.shared.debug("‼️ Make WalletModel for \(displayName) not derivation")
                    nonDeriveEntries.append(entry)
                } catch {
                    AppLog.shared.debug("‼️ Make WalletModel for \(displayName) catch error")
                    AppLog.shared.error(error)
                }

                return nil
            }

        walletModels.removeAll { walletModel in
            if !entries.contains(where: { $0.blockchainNetwork == walletModel.blockchainNetwork }) {
                AppLog.shared.debug("‼️ WalletModel will be removed \(walletModel.blockchainNetwork.blockchain.displayName)")
                return true
            }

            return false
        }

        walletModels.append(contentsOf: walletModelsToAdd)
        log(walletModels: walletModels)

        entriesWithoutDerivation.send(nonDeriveEntries)
        self.walletModels.send(walletModels)
    }

    func reloadWalletModels(silent: Bool) -> AnyPublisher<Void, Never> {
        guard !getWalletModels().isEmpty else {
            AppLog.shared.debug("‼️ WalletModels is empty")
            return .just
        }

        return reloadAllWalletModelsPublisher(silent: silent)
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return true
    }

    func canRemove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return false
    }

    func removeToken(_ token: Token, blockchainNetwork: BlockchainNetwork) {
        getWalletModels().first(where: { $0.blockchainNetwork == blockchainNetwork })?.removeToken(token)
        updateWalletModels()
    }
}

private extension CommonWalletListManager {
    func reloadAllWalletModelsPublisher(silent: Bool) -> AnyPublisher<Void, Never> {
        tryMigrateTokens()
            .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
                guard let self = self else {
                    return .just
                }

                return updateWalletModelsPublisher(silent: silent)
            }
            .eraseToAnyPublisher()
    }

    func updateWalletModelsPublisher(silent: Bool) -> AnyPublisher<Void, Never> {
        let publishers = getWalletModels().map {
            $0.update(silent: silent).replaceError(with: ())
        }

        return Publishers
            .MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        if migrated {
            return .just
        }

        migrated = true

        let items = userTokenListManager.getEntriesFromRepository()
        let itemsWithCustomTokens = items.filter { item in
            return item.tokens.contains(where: { $0.isCustom })
        }

        if itemsWithCustomTokens.isEmpty {
            return .just
        }

        let publishers: [AnyPublisher<Bool, Never>] = itemsWithCustomTokens.reduce(into: []) { result, item in
            result += item.tokens.filter { $0.isCustom }.map { token -> AnyPublisher<Bool, Never> in
                updateCustomToken(token: token, in: item.blockchainNetwork)
            }
        }

        return Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .handleEvents(receiveOutput: { [weak self] migrationResults in
                if migrationResults.contains(true) {
                    self?.updateWalletModels()
                }
            })
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(token: Token, in blockchainNetwork: BlockchainNetwork) -> AnyPublisher<Bool, Never> {
        let requestModel = CoinsListRequestModel(
            contractAddress: token.contractAddress,
            networkIds: [blockchainNetwork.blockchain.networkId]
        )

        return tangemApiService
            .loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .flatMap { [weak self] models -> AnyPublisher<Bool, Never> in
                guard let self = self,
                      let token = models.first?.items.compactMap({ $0.token }).first else {
                    return Just(false).eraseToAnyPublisher()
                }

                return Future<Bool, Never> { promise in
                    let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
                    self.userTokenListManager.update(.append([entry]))
                    promise(.success(true))
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func log(entires: [StorageEntry]) {
        let printList = entires.map { entry in
            var text = "blockchain: \(entry.blockchainNetwork.blockchain.displayName)"
            if !entry.tokens.isEmpty {
                text += " with tokens: \(entry.tokens.map { $0.name }.joined(separator: ", "))"
            }
            return text
        }

        AppLog.shared.debug("✅ Actual List of StorageEntry [\(printList.joined(separator: ", "))]")
    }

    func log(walletModels: [WalletModel]) {
        let printList = walletModels.map { walletModel in
            var text = "blockchain: \(walletModel.blockchainNetwork.blockchain.displayName)"
            if !walletModel.getTokens().isEmpty {
                text += " with tokens: \(walletModel.getTokens().map { $0.name }.joined(separator: ", "))"
            }
            return text
        }

        AppLog.shared.debug("✅ Actual List of WalletModels [\(printList.joined(separator: ", "))]")
    }
}
