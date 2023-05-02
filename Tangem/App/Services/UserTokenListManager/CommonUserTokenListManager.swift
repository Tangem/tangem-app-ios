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

    private(set) var didPerformInitialLoading: Bool = false

    private var userWalletId: Data
    private var tokenItemsRepository: TokenItemsRepository

    private var pendingTokensToUpdate: UserTokenList?
    private var loadTokensCancellable: AnyCancellable?
    private var saveTokensCancellable: AnyCancellable?
    private let hasTokenSynchronization: Bool

    init(config: UserWalletConfig, userWalletId: Data) {
        self.hasTokenSynchronization = config.hasFeature(.tokenSynchronization)
        self.userWalletId = userWalletId

        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
    }
}

// MARK: - UserTokenListManager

extension CommonUserTokenListManager: UserTokenListManager {
    func update(userWalletId: Data) {
        guard self.userWalletId != userWalletId else { return }

        self.userWalletId = userWalletId
        tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
    }

    func update(_ type: CommonUserTokenListManager.UpdateType) {
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

        if hasTokenSynchronization {
            updateTokensOnServer()
        }
    }

    func getEntriesFromRepository() -> [StorageEntry] {
        tokenItemsRepository.getItems()
    }

    func clearRepository(completion: @escaping () -> Void) {
        tokenItemsRepository.removeAll()
        updateTokensOnServer()
    }

    func updateLocalRepositoryFromServer(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        loadUserTokenList(result: result)
    }
}

// MARK: - Private

private extension CommonUserTokenListManager {
    // MARK: - Requests

    func loadUserTokenList(result: @escaping (Result<UserTokenList, Error>) -> Void) {
        if let list = pendingTokensToUpdate {
            tokenItemsRepository.update(mapToEntries(list: list))
            updateTokensOnServer(list: list, result: result)

            pendingTokensToUpdate = nil
            return
        }

        didPerformInitialLoading = true
        self.loadTokensCancellable = tangemApiService
            .loadTokens(for: userWalletId.hexString)
            .sink { [unowned self] completion in
                guard case .failure(let error) = completion else { return }

                if error.code == .notFound {
                    updateTokensOnServer(result: result)
                } else {
                    result(.failure(error as Error))
                }
            } receiveValue: { [unowned self] list in
                tokenItemsRepository.update(mapToEntries(list: list))
                result(.success(list))
            }
    }

    func updateTokensOnServer(
        list: UserTokenList? = nil,
        result: @escaping (Result<UserTokenList, Error>) -> Void = { _ in }
    ) {
        let listToUpdate = list ?? getUserTokenList()

        saveTokensCancellable = tangemApiService
            .saveTokens(list: listToUpdate, for: userWalletId.hexString)
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    result(.success(listToUpdate))
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
}

extension CommonUserTokenListManager {
    enum UpdateType {
        case rewrite(_ entries: [StorageEntry])
        case append(_ entries: [StorageEntry])
        case removeBlockchain(_ blockchain: BlockchainNetwork)
        case removeToken(_ token: Token, in: BlockchainNetwork)
    }
}
