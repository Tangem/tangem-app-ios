//
//  UserTokenListManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

// TODO: Andrey Fedorov - Get rid of `StorageEntry` in this interface (IOS-4152)
// TODO: Andrey Fedorov - Replace `UserTokenList` with model from the domain layer (IOS-4152)
protocol UserTokenListManager: UserTokensSyncService {
    var userTokens: [StorageEntry] { get }
    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { get }
    var userTokenList: AnyPublisher<UserTokenList, Never> { get }

    func update(with userTokenList: UserTokenList)
    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool)
    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void)
    func upload()
}
