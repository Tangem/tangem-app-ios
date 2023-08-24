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
    var userTokens: [StorageEntry] {
        let converter = _Converter()
        return converter.convertToStorageEntries(userTokensListSubject.value.entries)
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        let converter = _Converter()
        return userTokensListSubject
            .map { converter.convertToStorageEntries($0.entries) }
            .eraseToAnyPublisher()
    }

    var userTokensListPublisher: AnyPublisher<StorageEntriesList, Never> {
        userTokensListSubject.eraseToAnyPublisher()
    }

    var isInitialSyncPerformed: Bool {
        initialSyncSubject.value
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialSyncSubject.eraseToAnyPublisher()
    }

    private let initialSyncSubject = CurrentValueSubject<Bool, Never>(false)
    private let userTokensListSubject = CurrentValueSubject<StorageEntriesList, Never>(.empty)

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.initialSyncSubject.send(true)
        }
    }

    func update(with userTokenList: StorageEntriesList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func upload() {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let converter = _Converter()
            let blockchainNetwork = BlockchainNetwork(.ethereum(testnet: false))
            let tokens: [Token] = [
                .sushiMock,
                .shibaInuMock,
                .tetherMock,
            ]

            self.userTokensListSubject.send(
                .init(
                    entries: converter.convertToStoredUserTokens(tokens, in: blockchainNetwork),
                    grouping: .none,
                    sorting: .manual
                )
            )
            result(.success(()))
        }
    }
}
