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
    var userTokens: [StorageEntry] {
        []
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        .just(output: [])
    }

    var isInitialSyncPerformed: Bool { true }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    func contains(_ entry: StorageEntry) -> Bool {
        return false
    }

    func update(_ type: CommonUserTokenListManager.UpdateType, shouldUpload: Bool) {}

    func upload() {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {}

    func updateUserTokens() {}
}
