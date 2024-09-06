//
//  CommonStakingPendingTransactionsRepository.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class CommonStakingPendingTransactionsRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonStakingPendingTransactionsRepository.lockQueue")
    private var cache: Set<StakingPendingTransactionRecord> = [] {
        didSet {
            lockQueue.async { [weak self] in
                self?.saveChanges()
            }
        }
    }

    init() {
        loadPendingTransactions()
    }
}

// MARK: - StakingPendingTransactionsRepository

extension CommonStakingPendingTransactionsRepository: StakingPendingTransactionsRepository {
    func transactionDidSent(action: StakingAction) {
        let record = mapToStakingPendingTransactionRecord(action: action)
        cache.insert(record)
    }

    func checkIfConfirmed(balances: [StakingBalanceInfo]) {
        cache = cache.filter { record in
            switch record.type {
            case .stake, .voteLocked:
                return balances.contains { $0.validatorAddress == record.validator && $0.balanceType == .active }
            case .unstake:
                return !balances.contains { $0.validatorAddress == record.validator && $0.balanceType == .active }
            case .withdraw:
                return !balances.contains { $0.validatorAddress == record.validator && $0.balanceType == .withdraw }
            case .claimRewards, .restakeRewards:
                return !balances.contains { $0.amount == record.amount && $0.validatorAddress == record.validator }
            case .unlockLocked:
                return !balances.contains { $0.amount == record.amount && $0.balanceType == .locked }
            }
        }
    }

    func hasPending(balance: StakingBalanceInfo) -> Bool {
        switch balance.balanceType {
        case .locked:
            return cache.contains { $0.amount == balance.amount }
        case .active, .rewards, .unbonding, .warmup, .withdraw:
            return cache.contains { $0.validator == balance.validatorAddress }
        }
    }
}

// MARK: - Private

private extension CommonStakingPendingTransactionsRepository {
    private func loadPendingTransactions() {
        do {
            cache = try storage.value(for: .pendingStakingTransactions) ?? []
        } catch {
            log("Couldn't get the staking transactions list from the storage with error \(error)")
        }
    }

    private func saveChanges() {
        do {
            try storage.store(value: cache, for: .pendingStakingTransactions)
        } catch {
            log("Failed to save changes in storage. Reason: \(error)")
        }
    }

    private func mapToStakingPendingTransactionRecord(action: StakingAction) -> StakingPendingTransactionRecord {
        let type: StakingPendingTransactionRecord.ActionType = {
            switch action.type {
            case .stake: .stake
            case .unstake: .unstake
            case .pending(.withdraw): .withdraw
            case .pending(.claimRewards): .claimRewards
            case .pending(.restakeRewards): .restakeRewards
            case .pending(.voteLocked): .voteLocked
            case .pending(.unlockLocked): .unlockLocked
            }
        }()

        return StakingPendingTransactionRecord(amount: action.amount, validator: action.validator, type: type)
    }

    func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Staking Repository] \(message())")
    }
}
