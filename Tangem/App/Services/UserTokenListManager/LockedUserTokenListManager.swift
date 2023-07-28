//
//  LockedUserTokenListManager.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct LockedUserTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry] { [] }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { .just(output: []) }

    func contains(_ entry: StorageEntry) -> Bool {
        return false
    }

    func update(_ type: CommonUserTokenListManager.UpdateType, shouldUpload: Bool) {}

    func upload() {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        result(.success(()))
    }
}
