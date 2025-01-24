//
//  CommonUserTokensManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemSdk

class CommonUserTokensManager {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    let derivationManager: DerivationManager?

    private let userWalletId: UserWalletId
    private let shouldLoadExpressAvailability: Bool
    private let userTokenListManager: UserTokenListManager
    private let walletModelsManager: WalletModelsManager
    private let derivationStyle: DerivationStyle?
    private let existingCurves: [EllipticCurve]
    private let longHashesSupported: Bool

    weak var keysDerivingProvider: KeysDerivingProvider?

    private var pendingUserTokensSyncCompletions: [() -> Void] = []
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        shouldLoadExpressAvailability: Bool,
        userTokenListManager: UserTokenListManager,
        walletModelsManager: WalletModelsManager,
        derivationStyle: DerivationStyle?,
        derivationManager: DerivationManager?,
        existingCurves: [EllipticCurve],
        longHashesSupported: Bool
    ) {
        self.userWalletId = userWalletId
        self.shouldLoadExpressAvailability = shouldLoadExpressAvailability
        self.userTokenListManager = userTokenListManager
        self.walletModelsManager = walletModelsManager
        self.derivationStyle = derivationStyle
        self.derivationManager = derivationManager
        self.existingCurves = existingCurves
        self.longHashesSupported = longHashesSupported
    }

    private func getBlockchainNetwork(for tokenItem: TokenItem) -> BlockchainNetwork {
        if tokenItem.blockchainNetwork.derivationPath != nil {
            return tokenItem.blockchainNetwork
        }

        if let derivationStyle {
            let derivationPath = tokenItem.blockchain.derivationPath(for: derivationStyle)
            return BlockchainNetwork(tokenItem.blockchain, derivationPath: derivationPath)
        }

        return tokenItem.blockchainNetwork
    }

    private func addInternal(_ tokenItems: [TokenItem], shouldUpload: Bool) throws {
        let entries = try tokenItems.map { tokenItem in
            let blockchainNetwork = getBlockchainNetwork(for: tokenItem)
            try validateDerivation(for: tokenItem)
            return StorageEntry(blockchainNetwork: blockchainNetwork, token: tokenItem.token)
        }

        userTokenListManager.update(.append(entries), shouldUpload: shouldUpload)
    }

    private func removeInternal(_ tokenItem: TokenItem, shouldUpload: Bool) {
        guard canRemove(tokenItem) else {
            return
        }

        let blockchainNetwork = getBlockchainNetwork(for: tokenItem)

        if let token = tokenItem.token {
            userTokenListManager.update(.removeToken(token, in: blockchainNetwork), shouldUpload: shouldUpload)
        } else {
            userTokenListManager.update(.removeBlockchain(blockchainNetwork), shouldUpload: shouldUpload)
        }
    }

    private func loadSwapAvailabilityStateIfNeeded(forceReload: Bool) {
        guard shouldLoadExpressAvailability else { return }

        let converter = StorageEntryConverter()
        let tokenItems = converter.convertToTokenItem(userTokenListManager.userTokensList.entries)

        expressAvailabilityProvider.updateExpressAvailability(
            for: tokenItems,
            forceReload: forceReload,
            userWalletId: userWalletId.stringValue
        )
    }

    private func validateDerivation(for tokenItem: TokenItem) throws {
        if let derivationPath = tokenItem.blockchainNetwork.derivationPath,
           tokenItem.blockchain.curve == .ed25519_slip0010,
           derivationPath.nodes.contains(where: { !$0.isHardened }) {
            throw TangemSdkError.nonHardenedDerivationNotSupported
        }
    }

    private func handleUserTokensSync() {
        loadSwapAvailabilityStateIfNeeded(forceReload: true)
        walletModelsManager.updateAll(silent: false) { [weak self] in
            self?.handleWalletModelsUpdate()
        }
    }

    private func handleWalletModelsUpdate() {
        let completions = pendingUserTokensSyncCompletions
        pendingUserTokensSyncCompletions.removeAll()
        completions.forEach { $0() }
    }
}

// MARK: - UserTokensManager protocol conformance

extension CommonUserTokensManager: UserTokensManager {
    func deriveIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard let derivationManager,
              let interactor = keysDerivingProvider?.keysDerivingInteractor else {
            completion(.success(()))
            return
        }

        // Delay to update derivations in derivationManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            derivationManager.deriveKeys(cardInteractor: interactor, completion: completion)
        }
    }

    func contains(_ tokenItem: TokenItem) -> Bool {
        let blockchainNetwork = getBlockchainNetwork(for: tokenItem)

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

    func addTokenItemPrecondition(_ tokenItem: TokenItem) throws {
        if tokenItem.hasLongHashes, !longHashesSupported {
            throw Error.failedSupportedLongHashesTokens(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        if !existingCurves.contains(tokenItem.blockchain.curve) {
            throw Error.failedSupportedCurve(blockchainDisplayName: tokenItem.blockchain.displayName)
        }

        try validateDerivation(for: tokenItem)
    }

    func add(_ tokenItem: TokenItem) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            add(tokenItem) { result in
                continuation.resume(with: result)
            }
        }

        // wait for walletModelsManager to be updated
        try await Task.sleep(seconds: 0.1)

        let walletModelId = WalletModel.Id(tokenItem: tokenItem)

        guard let walletModel = walletModelsManager.walletModels.first(where: { $0.id == walletModelId.id }) else {
            throw CommonUserTokensManager.Error.addressNotFound
        }

        return walletModel.defaultAddress
    }

    func add(_ tokenItems: [TokenItem], completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        do {
            try addInternal(tokenItems, shouldUpload: true)
        } catch {
            completion(.failure(error.toTangemSdkError()))
            return
        }
        deriveIfNeeded(completion: completion)
    }

    func canRemove(_ tokenItem: TokenItem) -> Bool {
        guard tokenItem.isBlockchain else {
            return true
        }

        let blockchainNetwork = getBlockchainNetwork(for: tokenItem)

        guard let entry = userTokenListManager.userTokens.first(where: { $0.blockchainNetwork == blockchainNetwork }) else {
            return false
        }

        let hasNoTokens = entry.tokens.isEmpty
        return hasNoTokens
    }

    func remove(_ tokenItem: TokenItem) {
        removeInternal(tokenItem, shouldUpload: true)
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem], completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        do {
            try update(itemsToRemove: itemsToRemove, itemsToAdd: itemsToAdd)
        } catch {
            completion(.failure(error.toTangemSdkError()))
            return
        }

        deriveIfNeeded(completion: completion)
    }

    func update(itemsToRemove: [TokenItem], itemsToAdd: [TokenItem]) throws {
        itemsToRemove.forEach {
            removeInternal($0, shouldUpload: false)
        }

        try addInternal(itemsToAdd, shouldUpload: false)
        loadSwapAvailabilityStateIfNeeded(forceReload: true)
        userTokenListManager.upload()
    }

    func sync(completion: @escaping () -> Void) {
        defer {
            pendingUserTokensSyncCompletions.append(completion)
        }

        // Initiate a new update only if there is no ongoing update (i.e. `pendingUserTokensSyncCompletions` is empty)
        guard pendingUserTokensSyncCompletions.isEmpty else {
            return
        }

        userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.handleUserTokensSync()
        }
    }
}

// MARK: - UserTokensReordering protocol conformance

extension CommonUserTokensManager: UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModel.ID], Never> {
        return userTokenListManager
            .userTokensListPublisher
            .map { $0.entries.map(\.walletModelId) }
            .eraseToAnyPublisher()
    }

    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .userTokensListPublisher
            .map { converter.convert($0.grouping) }
            .eraseToAnyPublisher()
    }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        let converter = UserTokensReorderingOptionsConverter()
        return userTokenListManager
            .userTokensListPublisher
            .map { converter.convert($0.sorting) }
            .eraseToAnyPublisher()
    }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> {
        if actions.isEmpty {
            return .just
        }

        return Deferred { [userTokenListManager = self.userTokenListManager] in
            Future { promise in
                let converter = UserTokensReorderingOptionsConverter()
                let existingList = userTokenListManager.userTokensList
                var entries = existingList.entries
                var grouping = existingList.grouping
                var sorting = existingList.sorting

                for action in actions {
                    switch action {
                    case .setGroupingOption(let option):
                        grouping = converter.convert(option)
                    case .setSortingOption(let option):
                        sorting = converter.convert(option)
                    case .reorder(let reorderedWalletModelIds):
                        let userTokensKeyedByIds = entries.keyedFirst(by: \.walletModelId)
                        let reorderedEntries = reorderedWalletModelIds.compactMap { userTokensKeyedByIds[$0] }

                        // TODO: Refactor user tokens. Fix data layers mixing.
                        if reorderedEntries.count == entries.count {
                            entries = reorderedEntries
                        }
                    }
                }

                let editedList = StoredUserTokenList(
                    entries: entries,
                    grouping: grouping,
                    sorting: sorting
                )

                promise(.success((editedList, existingList)))
            }
            .filter { $0 != $1 }
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { input in
                let (userTokensManager, (editedList, existingList)) = input
                let logger = UserTokensReorderingLogger(walletModels: userTokensManager.walletModelsManager.walletModels)
                logger.logReorder(existingList: existingList, editedList: editedList, source: source)
            })
            .receive(on: DispatchQueue.main)
            .map { input in
                let (userTokensManager, (editedList, _)) = input
                userTokensManager.userTokenListManager.update(with: editedList)
            }
        }
        .eraseToAnyPublisher()
    }
}

extension CommonUserTokensManager {
    enum Error: Swift.Error, LocalizedError {
        case addressNotFound
        case failedSupportedLongHashesTokens(blockchainDisplayName: String)
        case failedSupportedCurve(blockchainDisplayName: String)

        var errorDescription: String? {
            switch self {
            case .failedSupportedLongHashesTokens(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedMessage(blockchainDisplayName)
            case .failedSupportedCurve(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedCurveMessage(blockchainDisplayName)
            case .addressNotFound:
                return nil
            }
        }
    }
}
