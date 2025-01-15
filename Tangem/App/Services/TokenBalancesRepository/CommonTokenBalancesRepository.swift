//
//  CommonTokenBalancesRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

struct CommonTokenBalancesRepository {
    @Injected(\.tokenBalancesStorage)
    private var storage: TokenBalancesStorage
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - TokenBalancesRepository

extension CommonTokenBalancesRepository: TokenBalancesRepository {
    func balance(wallet: WalletModel, type: CachedBalanceType) -> CachedBalance? {
        storage.balance(for: wallet.walletModelId, userWalletId: userWalletId, type: type)
    }

    func store(balance: CachedBalance, for wallet: WalletModel, type: CachedBalanceType) {
        storage.store(balance: balance, type: type, id: wallet.walletModelId, userWalletId: userWalletId)
    }
}
