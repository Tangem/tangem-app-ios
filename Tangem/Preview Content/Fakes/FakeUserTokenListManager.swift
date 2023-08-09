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
    var userTokens: [StorageEntry] {
        userTokensSubject.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        userTokensSubject.eraseToAnyPublisher()
    }

    var isInitialSyncPerformed: Bool {
        initialSyncSubject.value
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialSyncSubject.eraseToAnyPublisher()
    }

    private let initialSyncSubject = CurrentValueSubject<Bool, Never>(false)
    private let userTokensSubject = CurrentValueSubject<[StorageEntry], Never>([])

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.initialSyncSubject.send(true)
        }
    }

    func update(_ type: CommonUserTokenListManager.UpdateType, shouldUpload: Bool) {}

    func upload() {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.userTokensSubject.send([
                .init(
                    blockchainNetwork: .init(.ethereum(testnet: false)),
                    tokens: [
                        .sushiMock,
                        .shibaInuMock,
                        .tetherMock,
                    ]
                ),
            ])
            result(.success(()))
        }
    }
}
