//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

// TODO: Andrey Fedorov - The interface and responsibilities of this entity are one big mess, refactoring needed (IOS-4403)
protocol UserTokenListManager: UserTokensSyncService {
    var userTokens: [StorageEntry] { get }
    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { get }

    var userTokensList: StoredUserTokenList { get }
    var userTokensListPublisher: AnyPublisher<StoredUserTokenList, Never> { get }

    func update(with userTokenList: StoredUserTokenList)
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void)
    func upload()
}
