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
    private let balances: CurrentValueSubject<[String: StoredBalance], Never> = .init([:])
    private let lock = Lock(isRecursive: false)

    init(userWalletId: String) {
        self.userWalletId = userWalletId

        loadBalances()
    }
}

// MARK: - TokenBalancesRepository

extension CommonTokenBalancesRepository: TokenBalancesRepository {
    func balance(address: String, type: CachedBalanceType) -> CachedBalance? {
        let key = StoredBalanceKey(address: address, type: type).key
        return balances.value[key].map { mapToCachedBalance(balance: $0) }
    }

    func store(balance: CachedBalance, for address: String, type: CachedBalanceType) {
        let key = StoredBalanceKey(address: address, type: type).key
        let storedBalance = mapToStoredBalance(balance: balance)
        log("Store balance: \(storedBalance) for: \(key)")
        balances.value[key] = storedBalance
        save()
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenBalancesRepository: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self, userInfo: [
            "cachedBalancesCount": balances.value.count,
            "userWalletId": "\(userWalletId.prefix(4))...\(userWalletId.suffix(4))",
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
    struct StoredBalanceKey: Hashable, Codable, CustomStringConvertible {
        let address: String
        let type: CachedBalanceType

        var key: String {
            "\(type)_\(address)"
        }

        var description: String {
            "\(type) / \(address.prefix(4))...\(address.suffix(4))"
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
