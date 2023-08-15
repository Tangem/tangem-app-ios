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
    var isInitialSyncPerformed: Bool { true }

    var initialSyncPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userTokens: [StorageEntry.V3.Entry] { [] }

    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> { .just(output: []) }

    var userTokenList: AnyPublisher<UserTokenList, Never> { .just(output: .empty) }

    func contains(_ entry: StorageEntry.V2.Entry) -> Bool {
        return false
    }

    func update(with userTokenList: UserTokenList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {}

    func updateUserTokens() {}

    func upload() {}
}
