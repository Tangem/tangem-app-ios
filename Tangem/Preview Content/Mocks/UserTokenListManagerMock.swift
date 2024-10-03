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
    var initialized: Bool { true }

    var initializedPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userTokens: [StorageEntry] { [] }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { .just(output: []) }

    var userTokensList: StoredUserTokenList { .empty }

    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> { .just(output: .empty) }

    func update(with userTokenList: StoredUserTokenList) {}

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(_ completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func upload() {}
}
