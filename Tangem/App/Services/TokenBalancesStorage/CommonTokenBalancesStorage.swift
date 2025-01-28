//
//  CommonTokenBalancesStorage.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
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

    private let queue = DispatchQueue(label: "com.tangem.TokenBalancesStorage", attributes: .concurrent)
    private let balances: CurrentValueSubject<Balances, Never> = .init([:])
    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
        loadBalances()
    }
}

// MARK: - TokenBalancesStorage

extension CommonTokenBalancesStorage: TokenBalancesStorage {
    func store(balance: CachedBalance, type: CachedBalanceType, id: WalletModelId, userWalletId: UserWalletId) {
        queue.async(flags: .barrier) {
            var balancesForUserWallet = self.balances.value[userWalletId.stringValue, default: [:]]
            var balancesForWalletModel = balancesForUserWallet[id, default: [:]]
            balancesForWalletModel.updateValue(balance, forKey: type.rawValue)
            balancesForUserWallet.updateValue(balancesForWalletModel, forKey: id)
            self.balances.value.updateValue(balancesForUserWallet, forKey: userWalletId.stringValue)
        }
    }

    func balance(for id: WalletModelId, userWalletId: UserWalletId, type: CachedBalanceType) -> CachedBalance? {
        queue.sync {
            balances.value[userWalletId.stringValue]?[id]?[type.rawValue]
        }
    }
}

// MARK: - Private

private extension CommonTokenBalancesStorage {
    func bind() {
        balances
            .dropFirst()
            .removeDuplicates()
            // Add small debounce to reduce impact to write to disk operation
            .debounce(for: 0.5, scheduler: queue)
            .withWeakCaptureOf(self)
            .receiveValue { $0.save(balances: $1) }
            .store(in: &bag)
    }

    func loadBalances() {
        do {
            try balances.send(storage.value(for: .cachedBalances) ?? [:])
            AppLog.info(self, "Load successfully")
        } catch {
            AppLog.error(self, "Load error", error: error)
        }
    }

    private func save(balances: Balances) {
        do {
            try storage.store(value: balances, for: .cachedBalances)
        } catch {
            AppLog.error("Storage save error", error: error)
        }
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenBalancesStorage: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self, userInfo: [
            "balancesCount": balances.value.flatMap(\.value).flatMap(\.value).count,
        ])
    }
}
