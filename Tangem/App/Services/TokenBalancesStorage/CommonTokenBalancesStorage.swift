//
//  CommonTokenBalancesStorage.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class CommonTokenBalancesStorage {
    /**
     The balances are stored in this json structure
     ```
     {
        "userWalletId":{
            "wallet.id":{
                "available":{ "balance":0.1, "date":"date" },
                "staking":{ "balance":0.1, "date":"date" }
            }
        }
     }
     ```
     */
    private typealias Balances = [String: [String: [CachedBalanceType: CachedBalance]]]
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private var balances: Balances = [:]
    private let lock = Lock(isRecursive: false)

    init() {
        loadBalances()
    }
}

// MARK: - TokenBalancesStorage

extension CommonTokenBalancesStorage: TokenBalancesStorage {
    func store(balance: CachedBalance, type: CachedBalanceType, id: WalletModelId, userWalletId: UserWalletId) {
        lock.withLock {
            var balancesForWallet = balances[userWalletId.stringValue, default: [:]]
            balancesForWallet.updateValue([type: balance], forKey: id)
            balances.updateValue(balancesForWallet, forKey: userWalletId.stringValue)
            log(try! balances.json())
            save()
        }
    }

    func balance(for id: WalletModelId, userWalletId: UserWalletId, type: CachedBalanceType) -> CachedBalance? {
        lock.withLock {
            balances[userWalletId.stringValue]?[id]?[type]
        }
    }
}

// MARK: - Private

private extension CommonTokenBalancesStorage {
    func loadBalances() {
        do {
            balances = try storage.value(for: .cachedBalances) ?? [:]
            log("Load balances \(String(describing: balances))")
        } catch {
            log("Load balances error \(error.localizedDescription)")
            AppLog.shared.error(error)
        }
    }

    func save() {
        do {
            try storage.store(value: balances, for: .cachedBalances)
        } catch {
            log("Save balances error \(error.localizedDescription)")
            AppLog.shared.error(error)
        }
    }

    func log(_ message: String) {
        AppLog.shared.debug("[\(self)] \(message)")
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenBalancesStorage: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self, userInfo: [
            "balancesCount": balances.count,
        ])
    }
}
