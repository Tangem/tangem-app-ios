//
//  TokenBalancesRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenBalancesRepository {
    func availableBalance(tokenItem: TokenItem) -> CachedBalance?
    func stakingBalance(tokenItem: TokenItem) -> CachedBalance?

    func storeAvailable(balance: CachedBalance, for tokenItem: TokenItem)
    func storeStaking(balance: CachedBalance, for tokenItem: TokenItem)
}

struct CachedBalance: Hashable {
    let balance: Decimal
    let date: Date
}
