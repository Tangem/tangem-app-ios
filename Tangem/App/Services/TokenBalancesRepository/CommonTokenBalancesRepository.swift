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
    private let lockQueue = DispatchQueue(label: "com.tangem.TokenBalancesRepository.lockQueue")

    init(userWalletId: String) {
        self.userWalletId = userWalletId

        loadBalances()
    }
}

// MARK: - TokenBalancesRepository

extension CommonTokenBalancesRepository: TokenBalancesRepository {
    func availableBalance(tokenItem: TokenItem) -> CachedBalance? {
        let key = StoredBalanceKey(userWalletId: userWalletId, tokenItem: tokenItem, type: .available).key
        return balances.value[key].map { mapToCachedBalance(balance: $0) }
    }

    func stakingBalance(tokenItem: TokenItem) -> CachedBalance? {
        let key = StoredBalanceKey(userWalletId: userWalletId, tokenItem: tokenItem, type: .staked).key
        return balances.value[key].map { mapToCachedBalance(balance: $0) }
    }

    func storeStaking(balance: CachedBalance, for tokenItem: TokenItem) {
        let key = StoredBalanceKey(userWalletId: userWalletId, tokenItem: tokenItem, type: .staked).key
        let storedBalance = mapToStoredBalance(balance: balance)
        log("Store balance: \(storedBalance) for: \(key)")

        balances.value[key] = storedBalance
        save()
    }

    func storeAvailable(balance: CachedBalance, for tokenItem: TokenItem) {
        let key = StoredBalanceKey(userWalletId: userWalletId, tokenItem: tokenItem, type: .available).key
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
    struct StoredBalanceKey: Hashable, Codable, CustomStringConvertible {
        let userWalletId: String
        let tokenItem: TokenItem
        let type: StoredBalanceType

        var key: String {
            "\(userWalletId)_\(tokenItem.name)_\(type)"
        }

        var description: String {
            "\(tokenItem.name) / \(type)"
        }
    }

    struct StoredBalance: Hashable, Codable, CustomStringConvertible {
        let balance: Decimal
        let date: Date

        var description: String {
            "\(balance) / \(date.formatted(date: .abbreviated, time: .shortened))"
        }
    }

    enum StoredBalanceType: Hashable, Codable, CustomStringConvertible {
        case available
        case staked

        var description: String {
            switch self {
            case .available: "available"
            case .staked: "staked"
            }
        }
    }
}
