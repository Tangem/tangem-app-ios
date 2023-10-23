//
//  FakeUserTokenListManager.swift
//  Tangem
//
//  Created by Andrew Son on 02/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Token

class FakeUserTokenListManager: UserTokenListManager {
    var initialized: Bool {
        _initialized.value
    }

    var initializedPublisher: AnyPublisher<Bool, Never> {
        _initialized.eraseToAnyPublisher()
    }

    private let _initialized: CurrentValueSubject<Bool, Never>

    var userTokens: [StorageEntry] {
        let converter = StorageEntryConverter()
        return converter.convertToStorageEntries(userTokensListSubject.value.entries)
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        let converter = StorageEntryConverter()
        return userTokensListSubject
            .map { converter.convertToStorageEntries($0.entries) }
            .eraseToAnyPublisher()
    }

    var userTokensList: StoredUserTokenList { userTokensListSubject.value }

    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> {
        userTokensListSubject.eraseToAnyPublisher()
    }

    private let userTokensListSubject: CurrentValueSubject<StoredUserTokenList, Never>

    init(
        walletManagers: [FakeWalletManager],
        isDelayed: Bool
    ) {
        let entries = walletManagers
            .flatMap(\.walletModels)
            .map { walletModel in
                StoredUserTokenList.Entry(
                    id: walletModel.tokenItem.id,
                    name: walletModel.tokenItem.name,
                    symbol: walletModel.tokenItem.currencySymbol,
                    decimalCount: walletModel.tokenItem.blockchain.decimalCount,
                    blockchainNetwork: walletModel.blockchainNetwork,
                    contractAddress: walletModel.tokenItem.contractAddress
                )
            }

        let userTokenList = StoredUserTokenList(
            entries: entries,
            grouping: .none,
            sorting: .manual
        )

        userTokensListSubject = .init(isDelayed ? .empty : userTokenList)
        _initialized = .init(!isDelayed)

        if isDelayed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                self._initialized.send(true)
                self.userTokensListSubject.send(userTokenList)
            }
        }
    }

    func update(with userTokenList: StoredUserTokenList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func upload() {}

    func updateLocalRepositoryFromServer(_ completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let converter = StorageEntryConverter()
            let blockchainNetwork = BlockchainNetwork(.ethereum(testnet: false))
            let tokens: [Token] = [
                .sushiMock,
                .shibaInuMock,
                .tetherMock,
            ]
            let entries = tokens.map { converter.convertToStoredUserToken($0, in: blockchainNetwork) }

            self.userTokensListSubject.send(
                .init(
                    entries: entries,
                    grouping: .none,
                    sorting: .manual
                )
            )
            completion(.success(()))
        }
    }
}
