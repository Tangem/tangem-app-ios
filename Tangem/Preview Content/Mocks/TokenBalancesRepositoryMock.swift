//
//  TokenBalancesRepositoryMock.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenBalancesRepositoryMock: TokenBalancesRepository {
    func availableBalance(tokenItem: TokenItem) -> CachedBalance? { .none }

    func stakingBalance(tokenItem: TokenItem) -> CachedBalance? { .none }

    func storeAvailable(balance: CachedBalance, for tokenItem: TokenItem) {}

    func storeStaking(balance: CachedBalance, for tokenItem: TokenItem) {}
}
