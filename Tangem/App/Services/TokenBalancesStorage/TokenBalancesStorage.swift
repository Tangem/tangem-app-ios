//
//  TokenBalancesStorage 2.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenBalancesStorage {
    func store(balance: CachedBalance, type: CachedBalanceType, id: WalletModelId, userWalletId: String)
    func balance(for id: WalletModelId, userWalletId: String, type: CachedBalanceType) -> CachedBalance?
}

private struct TokenBalancesStorageKey: InjectionKey {
    static var currentValue: TokenBalancesStorage = CommonTokenBalancesStorage()
}

extension InjectedValues {
    var tokenBalancesStorage: TokenBalancesStorage {
        get { Self[TokenBalancesStorageKey.self] }
        set { Self[TokenBalancesStorageKey.self] = newValue }
    }
}
