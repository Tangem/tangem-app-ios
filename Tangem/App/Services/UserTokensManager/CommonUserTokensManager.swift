//
//  CommonUserTokensManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CommonUserTokensManager {
    private let userTokenListManager: UserTokenListManager
    private let walletModelsManager: WalletModelsManager
    private let derivationStyle: DerivationStyle?
    private let derivationManager: DerivationManager?
    private weak var cardDerivableProvider: CardDerivableProvider?

    init(
        userTokenListManager: UserTokenListManager,
        walletModelsManager: WalletModelsManager,
        derivationStyle: DerivationStyle?,
        derivationManager: DerivationManager?,
        cardDerivableProvider: CardDerivableProvider
    ) {
        self.userTokenListManager = userTokenListManager
        self.walletModelsManager = walletModelsManager
        self.derivationStyle = derivationStyle
        self.derivationManager = derivationManager
        self.cardDerivableProvider = cardDerivableProvider
    }

    private func makeBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork {
        if let derivationPath = derivationPath {
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        if let derivationStyle {
            let derivationPath = blockchain.derivationPaths(for: derivationStyle)[.default]
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        return BlockchainNetwork(blockchain, derivationPath: nil)
    }

    private func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard let derivationManager,
              let interactor = cardDerivableProvider?.cardDerivableInteractor else {
            completion(.success(()))
            return
        }

        derivationManager.deriveKeys(cardInteractor: interactor, completion: completion)
    }

    private func addInternal(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, shouldUpload: Bool) {
        let entries = tokenItems.map { tokenItem in
            let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)
            return StorageEntry(blockchainNetwork: blockchainNetwork, token: tokenItem.token)
        }

        userTokenListManager.update(.append(entries), shouldUpload: shouldUpload)
    }

    private func removeInternal(_ tokenItem: TokenItem, derivationPath: DerivationPath?, shouldUpload: Bool) {
        guard canRemove(tokenItem, derivationPath: derivationPath) else {
            return
        }

        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)

        if let token = tokenItem.token {
            userTokenListManager.update(.removeToken(token, in: blockchainNetwork), shouldUpload: shouldUpload)
        } else {
            userTokenListManager.update(.removeBlockchain(blockchainNetwork), shouldUpload: shouldUpload)
        }
    }
}

extension CommonUserTokensManager: UserTokensManager {
    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)

        guard let targetEntry = userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == blockchainNetwork }) else {
            return false
        }

        switch tokenItem {
        case .blockchain:
            return true
        case .token(let token, _):
            return targetEntry.tokens.contains(token)
        }
    }

    func getAllTokens(for blockchainNetwork: BlockchainNetwork) -> [Token] {
        let items = userTokenListManager.userTokens

        if let network = items.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return network.tokens
        }

        return []
    }

    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            add(tokenItem, derivationPath: derivationPath) { result in
                continuation.resume(with: result)
            }
        }

        // wait for walletModelsManager to be updated
        try await Task.sleep(seconds: 0.1)

        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)
        let walletModelId = WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: tokenItem.amountType)

        guard let walletModel = walletModelsManager.walletModels.first(where: { $0.id == walletModelId.id }) else {
            throw CommonUserTokensManager.Error.addressNotFound
        }

        return walletModel.defaultAddress
    }

    func add(_ tokenItems: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        addInternal(tokenItems, derivationPath: derivationPath, shouldUpload: true)
        deriveIfNeeded(completion: completion)
    }

    func canRemove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool {
        guard tokenItem.isBlockchain else {
            return true
        }

        let blockchainNetwork = makeBlockchainNetwork(for: tokenItem.blockchain, derivationPath: derivationPath)

        guard let entry = userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == blockchainNetwork }) else {
            return false
        }

        let hasNoTokens = entry.tokens.isEmpty
        return hasNoTokens
    }

    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?) {
        removeInternal(tokenItem, derivationPath: derivationPath, shouldUpload: true)
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        itemsToRemove.forEach {
            removeInternal($0, derivationPath: derivationPath, shouldUpload: false)
        }

        addInternal(itemsToAdd, derivationPath: nil, shouldUpload: false)
        userTokenListManager.upload()
        deriveIfNeeded(completion: completion)
    }
}

extension CommonUserTokensManager {
    enum Error: Swift.Error {
        case addressNotFound
    }
}
