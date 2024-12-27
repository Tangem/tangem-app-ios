//
//  TokenBalancesRepositoryMock.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenBalancesRepositoryMock: TokenBalancesRepository {
    func balance(wallet: WalletModel, type: CachedBalanceType) -> CachedBalance? { .none }

    func store(balance: CachedBalance, for wallet: WalletModel, type: CachedBalanceType) {}
}
