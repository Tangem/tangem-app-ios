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
    private let supportedBlockchains: Set<Blockchain>
    private let hasTokenSynchronization: Bool
    private let hdWalletsSupported: Bool // hotfix migration

    private let tokenItemsRepository: TokenItemsRepository
    private let initialTokenSyncSubject: CurrentValueSubject<Bool, Never>
    private let userTokenListSubject: CurrentValueSubject<StoredUserTokenList, Never>

    private var pendingTokensToUpdate: UserTokenList?
    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?

    /// Bool flag for migration custom token to token form our API
    private var migrated = false

    init(
        userWalletId: Data,
        supportedBlockchains: Set<Blockchain>,
        hdWalletsSupported: Bool,
        hasTokenSynchronization: Bool
    ) {
        self.userWalletId = userWalletId
        self.supportedBlockchains = supportedBlockchains
        self.hdWalletsSupported = hdWalletsSupported
        self.hasTokenSynchronization = hasTokenSynchronization

        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
        initialTokenSyncSubject = CurrentValueSubject(tokenItemsRepository.containsFile)
        userTokenListSubject = CurrentValueSubject(tokenItemsRepository.getList())

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
    var userTokens: [StorageEntry] {
        let converter = _Converter()
        return converter.convertToStorageEntries(userTokenListSubject.value.entries)
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        let converter = _Converter()
        return userTokenListSubject
            .map { converter.convertToStorageEntries($0.entries) }
            .eraseToAnyPublisher()
    }

    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> {
        userTokenListSubject.eraseToAnyPublisher()
    }

    func update(with userTokenList: StoredUserTokenList) {
        tokenItemsRepository.update(userTokenList)

        notifyAboutTokenListUpdates()
    }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {
        let converter = _Converter()

        // TODO: Andrey Fedorov - Or update the whole list instead?
        switch type {
        case .append(let entries):
            let storedUserTokens = converter.convertToStoredUserTokens(entries)
            tokenItemsRepository.append(storedUserTokens)
        case .removeBlockchain(let blockchainNetwork):
            tokenItemsRepository.remove([blockchainNetwork])
        case .removeToken(let token, let blockchainNetwork):
            let storedUserTokens = converter.convertToStoredUserTokens([token], in: blockchainNetwork)
            tokenItemsRepository.remove(storedUserTokens)
        }

        notifyAboutTokenListUpdates()

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
        tokenItemsRepository.containsFile
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialTokenSyncSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    func notifyAboutTokenListUpdates() {
        userTokenListSubject.send(tokenItemsRepository.getList())
    }

    // MARK: - Requests

    func loadUserTokenList(result: @escaping (Result<Void, Error>) -> Void) {
        if let list = pendingTokensToUpdate {
            let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)

            tokenItemsRepository.update(converter.convertRemoteToStored(list))
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
                let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)

                tokenItemsRepository.update(converter.convertRemoteToStored(list))
                notifyAboutTokenListUpdates()
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
        let converter = UserTokenListConverter(supportedBlockchains: supportedBlockchains)
        let list = tokenItemsRepository.getList()
        return converter.convertStoredToRemote(list)
    }

    // MARK: - Token upgrading

    func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        if migrated {
            return .just
        }

        migrated = true

        let list = tokenItemsRepository.getList()
        let customUserTokens = list.entries.filter { $0.isCustom }

        if customUserTokens.isEmpty {
            return .just
        }

        let publishers = customUserTokens.map(updateCustomToken(_:))

        return Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func updateCustomToken(_ token: StoredUserTokenList.Entry) -> AnyPublisher<Bool, Never> {
        let blockchainNetwork = token.blockchainNetwork

        let requestModel = CoinsList.Request(
            supportedBlockchains: [blockchainNetwork.blockchain],
            contractAddress: token.contractAddress
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
                    let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
                    self?.update(.append([entry]), shouldUpload: true)
                    promise(.success(true))
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // Remove tokens with derivation for cards without derivation
    func removeInvalidTokens() {
        guard !hdWalletsSupported else {
            return
        }

        let list = tokenItemsRepository.getList()
        let badEntries = list.entries.filter { $0.blockchainNetwork.derivationPath != nil }

        guard !badEntries.isEmpty else {
            return
        }

        let blockchainNetwork = badEntries.map { $0.blockchainNetwork }
        tokenItemsRepository.remove(blockchainNetwork)
    }
}
