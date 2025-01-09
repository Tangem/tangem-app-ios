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

    private let balances: CurrentValueSubject<[String: StoredBalance], Never> = .init([:])
    private let lock = Lock(isRecursive: false)

    init() {
        loadBalances()
    }
}

// MARK: - TokenBalancesRepository

extension CommonTokenBalancesRepository: TokenBalancesRepository {
    func balance(wallet: WalletModel, type: CachedBalanceType) -> CachedBalance? {
        let key = StoredBalanceKey(walletModel: wallet, type: type)
        return balances.value[key.key].map { mapToCachedBalance(balance: $0) }
    }

    func store(balance: CachedBalance, for wallet: WalletModel, type: CachedBalanceType) {
        let key = StoredBalanceKey(walletModel: wallet, type: type)
        let storedBalance = mapToStoredBalance(balance: balance)
        log("Store balance: \(storedBalance) for: \(key)")
        balances.value[key.key] = storedBalance
        save()
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenBalancesRepository: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self, userInfo: [
            "balancesCount": balances.value.count,
        ])
    }
}

// MARK: - Private

private extension CommonTokenBalancesRepository {
    func mapToStoredBalance(balance: CachedBalance) -> StoredBalance {
        .init(balance: balance.balance, date: balance.date)
    }

    func mapToCachedBalance(balance: StoredBalance) -> CachedBalance {
        .init(balance: balance.balance, date: balance.date)
    }

    func loadBalances() {
        do {
            let cached: [String: StoredBalance]? = try storage.value(for: .cachedBalances)
            log("Load balances \(String(describing: cached))")
            balances.send(cached ?? [:])
        } catch {
            log("Load balances error \(error.localizedDescription)")
            AppLog.shared.error(error)
        }
    }

    func save() {
        lock.withLock {
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
    struct StoredBalanceKey: CustomStringConvertible {
        private let walletModel: WalletModel
        private let type: CachedBalanceType

        var key: String {
            [
                walletModel.tokenItem.name,
                walletModel.tokenItem.contractAddress ?? "coin",
                walletModel.defaultAddress,
                type.rawValue,
            ].joined(separator: "_")
        }

        var description: String {
            let address = "\(walletModel.defaultAddress.prefix(4))...\(walletModel.defaultAddress.suffix(4))"
            return "\(walletModel.tokenItem.name) / \(address) / \(type)"
        }

        init(walletModel: WalletModel, type: CachedBalanceType) {
            self.walletModel = walletModel
            self.type = type
        }
    }

    struct StoredBalance: Hashable, Codable, CustomStringConvertible {
        let balance: Decimal
        let date: Date

        var description: String {
            "\(balance) / \(date.formatted(date: .abbreviated, time: .shortened))"
        }
    }
}
