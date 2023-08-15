//
//  FakeUserTokenListManager.swift
//  Tangem
//
//  Created by Andrew Son on 02/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeUserTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry.V3.Entry] {
        userTokensSubject.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> {
        userTokensSubject.eraseToAnyPublisher()
    }

    var isInitialSyncPerformed: Bool {
        initialSyncSubject.value
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialSyncSubject.eraseToAnyPublisher()
    }

    var userTokenList: AnyPublisher<UserTokenList, Never> {
        userTokenListSubject
            .delay(for: 3, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private let initialSyncSubject = CurrentValueSubject<Bool, Never>(false)
    private let userTokensSubject = CurrentValueSubject<[StorageEntry.V3.Entry], Never>([])
    private let userTokenListSubject = CurrentValueSubject<UserTokenList, Never>(UserTokenListStubs.walletUserWalletList)

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.initialSyncSubject.send(true)
        }
    }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func update(with userTokenList: UserTokenList) {
        userTokenListSubject.send(userTokenList)
    }

    func upload() {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let converter = StorageEntriesConverter()
            let blockchainNetwork = BlockchainNetwork(.ethereum(testnet: false))
            let storageEntries = [
                converter.convert(blockchainNetwork),
                converter.convert(.sushiMock, in: blockchainNetwork),
                converter.convert(.shibaInuMock, in: blockchainNetwork),
                converter.convert(.tetherMock, in: blockchainNetwork),
            ]
            self.userTokensSubject.send(storageEntries)
            result(.success(()))
        }
    }
}
