//
//  TokenBalancesRepositoryMock.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TokenBalancesRepositoryMock: TokenBalancesRepository {
    func balance(wallet: WalletModel, type: CachedBalanceType) -> CachedBalance? { nil }

    func store(balance: CachedBalance, for wallet: WalletModel, type: CachedBalanceType) {}
}
