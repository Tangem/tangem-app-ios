//
//  UserTokenListManagerMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct UserTokenListManagerMock: UserTokenListManager {
    var userTokensListPublisher: AnyPublisher<StorageEntriesList, Never> { fatalError() }

    func update(with userTokenList: StorageEntriesList) {
        fatalError()
    }

    var isInitialSyncPerformed: Bool { true }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userTokens: [StorageEntry] { [] }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { .just(output: []) }

    var userTokenList: AnyPublisher<UserTokenList, Never> { fatalError() }

    func contains(_ entry: StorageEntry) -> Bool {
        return false
    }

    func update(with userTokenList: UserTokenList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {}

    func updateUserTokens() {}

    func upload() {}
}
