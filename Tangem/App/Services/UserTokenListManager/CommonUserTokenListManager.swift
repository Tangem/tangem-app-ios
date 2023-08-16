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
    private let tokenItemsRepository: _TokenItemsRepository
    private let supportedBlockchains: Set<Blockchain>

    private var pendingTokensToUpdate: UserTokenList?
    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?
    private let hasTokenSynchronization: Bool
    private let hdWalletsSupported: Bool // hotfix migration
    /// Bool flag for migration custom token to token form our API
    private var migrated = false

    private let initialTokenSyncSubject: CurrentValueSubject<Bool, Never>
    private var _userTokens: CurrentValueSubject<[StorageEntry.V3.Entry], Never>
    private var _userTokenList: CurrentValueSubject<UserTokenList, Never>

    init(hasTokenSynchronization: Bool, userWalletId: Data, supportedBlockchains: Set<Blockchain>, hdWalletsSupported: Bool) {
        self.hasTokenSynchronization = hasTokenSynchronization
        self.userWalletId = userWalletId
        self.supportedBlockchains = supportedBlockchains
        self.hdWalletsSupported = hdWalletsSupported
        tokenItemsRepository = _CommonTokenItemsRepository(key: userWalletId.hexString)
        initialTokenSyncSubject = CurrentValueSubject(tokenItemsRepository.isInitialized)
        _userTokens = .init(tokenItemsRepository.getItems())
        _userTokenList = .init(.empty)
        removeInvalidTokens()
        performInitialSync()
    }

    private func performInitialSync() {
        if isInitialSyncPerformed {
            return
        }

        updateLocalRepositoryFromServer { [weak self] _ in
            self?.initialTokenSyncSubject.send(true)
        }
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry.V3.Entry] {
        _userTokens.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> {
        _userTokens.eraseToAnyPublisher()
    }

    var userTokenList: AnyPublisher<UserTokenList, Never> {
        _userTokenList.eraseToAnyPublisher()
    }

    func update(with userTokenList: UserTokenList) {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4152)
    }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {
        switch type {
        case .rewrite(let entries):
            tokenItemsRepository.update(entries)
        case .append(let entries):
            tokenItemsRepository.append(entries)
        case .removeBlockchain(let blockchain):
            tokenItemsRepository.remove([blockchain])
        case .removeToken(let token, let network):
            let converter = StorageEntriesConverter()
            let storageEntry = converter.convert(token, in: network)
            tokenItemsRepository.remove([storageEntry])
        }

        updateUserTokens()

        if shouldUpload {
            updateTokensOnServer()
        }
    }

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        guard hasTokenSynchronization else {
            result(.success(()))
            return
        }

        loadUserTokenList(result: result)
    }

    func upload() {
        guard hasTokenSynchronization else { return }

        updateTokensOnServer()
    }
}

extension CommonUserTokenListManager: UserTokensSyncService {
    var isInitialSyncPerformed: Bool {
        tokenItemsRepository.isInitialized
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialTokenSyncSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func updateUserTokens() {
        _userTokens.send(tokenItemsRepository.getItems())
    }

    func updateUserTokenList(with userTokenList: UserTokenList) {
        _userTokenList.send(userTokenList)
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
                updateUserTokens()
                updateUserTokenList(with: list)
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
        return UserTokenList(
            tokens: tokens,
            group: .none,
            sort: .manual
        )
    }

    // MARK: - Mapping

    func mapToTokens(entries: [StorageEntry.V3.Entry]) -> [UserTokenList.Token] {
        return entries.map { entry in
            return UserTokenList.Token(
                id: entry.id,
                networkId: entry.networkId,
                name: entry.name,
                symbol: entry.symbol,
                decimals: entry.decimals,
                derivationPath: entry.blockchainNetwork.derivationPath,
                contractAddress: entry.contractAddress
            )
        }
    }

    func mapToEntries(list: UserTokenList) -> [StorageEntry.V3.Entry] {
        return list.tokens.compactMap { token -> StorageEntry.V3.Entry? in
            guard let blockchain = supportedBlockchains[token.networkId] else {
                return nil
            }

            let blockchainNetwork = StorageEntry.V3.BlockchainNetwork(blockchain, derivationPath: token.derivationPath)

            return StorageEntry.V3.Entry(
                id: token.id,
                networkId: token.networkId,
                name: token.name,
                symbol: token.symbol,
                decimals: token.decimals,
                blockchainNetwork: blockchainNetwork,
                contractAddress: token.contractAddress
            )
        }
    }

    // MARK: - Token upgrading

    func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        if migrated {
            return .just
        }

        migrated = true

        let items = tokenItemsRepository.getItems()
        let customTokens = items.filter(\.isCustom)

        if customTokens.isEmpty {
            return .just
        }

        let publishers = customTokens.map(updateCustomToken(_:))

        return Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(_ storageEntry: StorageEntry.V3.Entry) -> AnyPublisher<Bool, Never> {
        let blockchainNetwork = storageEntry.blockchainNetwork
        let requestModel = CoinsList.Request(
            supportedBlockchains: [blockchainNetwork.blockchain],
            contractAddress: storageEntry.contractAddress
        )

        // TODO: refactor, reduce complexity
        return tangemApiService
            .loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .flatMap { [weak self] models -> AnyPublisher<Bool, Never> in
                return Future<Bool, Never> { promise in
                    guard let token = models.first?.items.compactMap({ $0.token }).first else {
                        promise(.success(false))
                        return
                    }

                    let converter = StorageEntriesConverter()
                    let updatedStorageEntry = converter.convert(token, in: blockchainNetwork)
                    self?.update(.append([updatedStorageEntry]), shouldUpload: true)
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
