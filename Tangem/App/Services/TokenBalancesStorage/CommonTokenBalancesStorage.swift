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
    private typealias Balances = [String: [String: [String: CachedBalance]]]
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
            var balancesForUserWallet = balances[userWalletId.stringValue, default: [:]]
            var balancesForWalletModel = balancesForUserWallet[id, default: [:]]
            balancesForWalletModel.updateValue(balance, forKey: type.rawValue)
            balancesForUserWallet.updateValue(balancesForWalletModel, forKey: id)
            balances.updateValue(balancesForUserWallet, forKey: userWalletId.stringValue)
            save()
        }
    }

    func balance(for id: WalletModelId, userWalletId: UserWalletId, type: CachedBalanceType) -> CachedBalance? {
        lock.withLock {
            balances[userWalletId.stringValue]?[id]?[type.rawValue]
        }
    }
}

// MARK: - Private

private extension CommonTokenBalancesStorage {
    func loadBalances() {
        do {
            balances = try storage.value(for: .cachedBalances) ?? [:]
            log("Storage load successfully")
        } catch {
            log("Storage load error \(error.localizedDescription)")
            AppLog.shared.error(error)
        }
    }

    func save() {
        do {
            try storage.store(value: balances, for: .cachedBalances)
            log("Storage save successfully")
        } catch {
            log("Storage save error \(error.localizedDescription)")
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
            "balancesCount": balances.flatMap(\.value).flatMap(\.value).count,
        ])
    }
}
