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

class CommonTokenBalancesRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let userWalletId: String
    private let balances: CurrentValueSubject<[StoredBalance], Never> = .init([])
    private let lockQueue = DispatchQueue(label: "com.tangem.TokenBalancesRepository.lockQueue")

    init(userWalletId: String) {
        self.userWalletId = userWalletId

        loadBalances()
    }
}

// MARK: - TokenBalancesRepository

extension CommonTokenBalancesRepository: TokenBalancesRepository {
    func availableBalance(tokenItem: TokenItem) -> CachedBalance? {
        balances.value
            .first(where: { filter(balance: $0, for: tokenItem, type: .available) })
            .map { mapToCachedBalance(balance: $0) }
    }

    func stakingBalance(tokenItem: TokenItem) -> CachedBalance? {
        balances.value
            .first(where: { filter(balance: $0, for: tokenItem, type: .staked) })
            .map { mapToCachedBalance(balance: $0) }
    }

    func storeStaking(balance: CachedBalance, for tokenItem: TokenItem) {
        var balances = balances.value
        balances.append(mapToStoredBalance(item: tokenItem, balance: balance, type: .staked))
        self.balances.send(balances)
        save()
    }

    func storeAvailable(balance: CachedBalance, for tokenItem: TokenItem) {
        var balances = balances.value
        balances.append(mapToStoredBalance(item: tokenItem, balance: balance, type: .available))
        self.balances.send(balances)
        save()
    }
}

extension CommonTokenBalancesRepository: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self)
    }
}

// MARK: - Private

private extension CommonTokenBalancesRepository {
    func filter(balance: StoredBalance, for item: TokenItem, type: StoredBalanceType) -> Bool {
        balance.userWalletId == userWalletId && balance.tokenItem == item && balance.type == type
    }

    func mapToStoredBalance(item: TokenItem, balance: CachedBalance, type: StoredBalanceType) -> StoredBalance {
        .init(userWalletId: userWalletId, tokenItem: item, balance: balance.balance, type: type, date: balance.date)
    }

    func mapToCachedBalance(balance: StoredBalance) -> CachedBalance {
        .init(balance: balance.balance, date: balance.date)
    }

    func loadBalances() {
        do {
            let cached: [StoredBalance]? = try storage.value(for: .cachedBalances)
            balances.send(cached ?? [])
        } catch {
            log("Load balances error \(error.localizedDescription)")
            AppLog.shared.error(error)
        }
    }

    func save() {
        lockQueue.sync {
            do {
                try storage.store(value: balances.value, for: .cachedBalances)
            } catch {
                log("Save balances error \(error.localizedDescription)")
                AppLog.shared.error(error)
            }
        }
    }

    func log(_ message: String) {
        AppLog.shared.debug("[\(self)] \(message)")
    }
}

private extension CommonTokenBalancesRepository {
    struct StoredBalance: Hashable, Codable {
        let userWalletId: String
        let tokenItem: TokenItem
        let balance: Decimal
        let type: StoredBalanceType
        let date: Date
    }

    enum StoredBalanceType: Hashable, Codable {
        case available
        case staked
    }
}
