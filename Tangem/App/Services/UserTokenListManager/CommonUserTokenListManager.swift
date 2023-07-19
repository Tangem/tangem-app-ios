//
//  CommonUserTokenListManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.Token
import struct TangemSdk.DerivationPath

class CommonUserTokenListManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: Data
    private let tokenItemsRepository: TokenItemsRepository

    private var pendingTokensToUpdate: UserTokenList?
    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?
    private let hasTokenSynchronization: Bool
    private let hdWalletsSupported: Bool // hotfix migration
    /// Bool flag for migration custom token to token form our API
    private var migrated = false

    private var _userTokens: CurrentValueSubject<[StorageEntry], Never>

    init(hasTokenSynchronization: Bool, userWalletId: Data, hdWalletsSupported: Bool) {
        self.hasTokenSynchronization = hasTokenSynchronization
        self.userWalletId = userWalletId
        self.hdWalletsSupported = hdWalletsSupported
        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
        _userTokens = .init(tokenItemsRepository.getItems())
        removeInvalidTokens()
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry] {
        _userTokens.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        _userTokens.eraseToAnyPublisher()
    }

    func update(_ type: CommonUserTokenListManager.UpdateType, shouldUpload: Bool) {
        switch type {
        case .rewrite(let entries):
            tokenItemsRepository.update(entries)
        case .append(let entries):
            tokenItemsRepository.append(entries)
        case .removeBlockchain(let blockchain):
            tokenItemsRepository.remove([blockchain])
        case .removeToken(let token, let network):
            tokenItemsRepository.remove([token], blockchainNetwork: network)
        }

        sendUpdate()

        if shouldUpload {
            updateTokensOnServer()
        }
    }

    func upload() {
        guard hasTokenSynchronization else { return }

        updateTokensOnServer()
    }

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        guard hasTokenSynchronization else {
            result(.success(()))
            return
        }

        loadUserTokenList(result: result)
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func sendUpdate() {
        _userTokens.send(tokenItemsRepository.getItems())
    }

    // MARK: - Requests

    func loadUserTokenList(result: @escaping (Result<Void, Error>) -> Void) {
        if let list = pendingTokensToUpdate {
            tokenItemsRepository.update(mapToEntries(list: list))
            updateTokensOnServer(list: list, result: result)

            pendingTokensToUpdate = nil
            return
        }

        let loadTokensPublisher = tangemApiService.loadTokens(for: userWalletId.hexString)
        let upgradeTokensPublisher = tryMigrateTokens().setFailureType(to: TangemAPIError.self)

        self.loadTokensCancellable = loadTokensPublisher
            .combineLatest(upgradeTokensPublisher)
            .sink { [unowned self] completion in
                guard case .failure(let error) = completion else { return }

                if error.code == .notFound {
                    updateTokensOnServer(result: result)
                } else {
                    result(.failure(error as Error))
                }
            } receiveValue: { [unowned self] list, _ in
                tokenItemsRepository.update(mapToEntries(list: list))
                sendUpdate()
                result(.success(()))
            }
    }

    func updateTokensOnServer(
        list: UserTokenList? = nil,
        result: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        let listToUpdate = list ?? getUserTokenList()

        saveTokensCancellable = tangemApiService
            .saveTokens(list: listToUpdate, for: userWalletId.hexString)
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    result(.success(()))
                case .failure(let error):
                    self.pendingTokensToUpdate = listToUpdate
                    result(.failure(error))
                }
            }
    }

    func getUserTokenList() -> UserTokenList {
        let entries = tokenItemsRepository.getItems()
        let tokens = mapToTokens(entries: entries)
        return UserTokenList(tokens: tokens)
    }

    // MARK: - Mapping

    func mapToTokens(entries: [StorageEntry]) -> [UserTokenList.Token] {
        entries.reduce(into: []) { result, entry in
            let blockchain = entry.blockchainNetwork.blockchain
            let blockchainToken = UserTokenList.Token(
                id: blockchain.id,
                networkId: blockchain.networkId,
                name: blockchain.displayName,
                symbol: blockchain.currencySymbol,
                decimals: blockchain.decimalCount,
                derivationPath: entry.blockchainNetwork.derivationPath,
                contractAddress: nil
            )
            if !result.contains(blockchainToken) {
                result.append(blockchainToken)
            }

            entry.tokens.forEach { token in
                let token = UserTokenList.Token(
                    id: token.id,
                    networkId: blockchain.networkId,
                    name: token.name,
                    symbol: token.symbol,
                    decimals: token.decimalCount,
                    derivationPath: entry.blockchainNetwork.derivationPath,
                    contractAddress: token.contractAddress
                )

                if !result.contains(token) {
                    result.append(token)
                }
            }
        }
    }

    func mapToEntries(list: UserTokenList) -> [StorageEntry] {
        let blockchains = list.tokens
            .filter { $0.contractAddress == nil }
            .compactMap { token -> BlockchainNetwork? in
                guard let blockchain = Blockchain(from: token.networkId) else {
                    return nil
                }

                return BlockchainNetwork(blockchain, derivationPath: token.derivationPath)
            }

        var entries: [StorageEntry] = []

        blockchains.forEach { network in
            let entry = StorageEntry(
                blockchainNetwork: network,
                tokens: list.tokens
                    .filter { $0.contractAddress != nil && $0.networkId == network.blockchain.networkId && $0.derivationPath == network.derivationPath }
                    .map { token in
                        Token(
                            name: token.name,
                            symbol: token.symbol,
                            contractAddress: token.contractAddress!,
                            decimalCount: token.decimals,
                            id: token.id
                        )
                    }
            )

            if !entries.contains(entry) {
                entries.append(entry)
            }
        }

        return entries
    }

    // MARK: - Token upgrading

    func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        if migrated {
            return .just
        }

        migrated = true

        let items = tokenItemsRepository.getItems()
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
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(token: Token, in blockchainNetwork: BlockchainNetwork) -> AnyPublisher<Bool, Never> {
        let requestModel = CoinsListRequestModel(
            contractAddress: token.contractAddress,
            networkIds: [blockchainNetwork.blockchain.networkId]
        )

        // TODO: refactor, reduce complexity
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
                    self.update(.append([entry]), shouldUpload: true)
                    promise(.success(true))
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // Remove tokens with derivation for cards without derivation
    private func removeInvalidTokens() {
        guard !hdWalletsSupported else {
            return
        }

        let allItems = tokenItemsRepository.getItems()
        let badItems = allItems.filter { $0.blockchainNetwork.derivationPath != nil }
        guard !badItems.isEmpty else {
            return
        }

        let networks = badItems.map { $0.blockchainNetwork }
        tokenItemsRepository.remove(networks)
    }
}

extension CommonUserTokenListManager {
    enum UpdateType {
        case rewrite(_ entries: [StorageEntry])
        case append(_ entries: [StorageEntry])
        case removeBlockchain(_ blockchain: BlockchainNetwork)
        case removeToken(_ token: Token, in: BlockchainNetwork)
    }
}
