//
//  SolanaDummyAccountStorage.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

class SolanaDummyAccountStorage: SolanaAccountStorage {
    enum SolanaDummyAccountStorageError: Error {
        case notImplemented
    }

    func save(_ account: Account) -> Result<Void, Error> {
        return .failure(SolanaDummyAccountStorageError.notImplemented)
    }

    var account: Result<Account, Error> {
        return .failure(SolanaDummyAccountStorageError.notImplemented)
    }

    func clear() -> Result<Void, Error> {
        return .failure(SolanaDummyAccountStorageError.notImplemented)
    }
}
