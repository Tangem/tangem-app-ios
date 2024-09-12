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
    var records: [StakingPendingTransactionRecord] { cache.asArray }

    func transactionDidSent(action: StakingAction, validator: ValidatorInfo?) {
        let record = mapToStakingPendingTransactionRecord(action: action, validator: validator)
        log("Will be add record - \(record)")

        cache.insert(record)
    }

    func checkIfConfirmed(balances: [StakingBalanceInfo]) {
        cache = cache.filter { record in
            let shouldDelete: Bool = {
                switch record.type {
                case .stake, .voteLocked:
                    balances.contains { balance in
                        compare(record, balance, by: [.validator, .type([.active, .warmup])])
                    }
                case .unstake:
                    !balances.contains { balance in
                        compare(record, balance, by: [.validator, .type([.active]), .amount])
                    }
                case .withdraw:
                    !balances.contains { balance in
                        compare(record, balance, by: [.validator, .type([.unstaked]), .amount])
                    }
                case .claimRewards, .restakeRewards:
                    !balances.contains { balance in
                        compare(record, balance, by: [.validator, .type([.rewards]), .amount])
                    }
                case .unlockLocked:
                    !balances.contains { balance in
                        compare(record, balance, by: [.type([.locked]), .amount])
                    }
                }
            }()

            log("Record \(record) will be delete - \(shouldDelete)")
            return !shouldDelete
        }
    }

    func hasPending(balance: StakingBalanceInfo) -> Bool {
        let hasPending: Bool
        switch balance.balanceType {
        case .locked:
            hasPending = cache.contains { $0.amount == balance.amount }
        case .active, .rewards, .unbonding, .warmup, .unstaked:
            hasPending = cache.contains { $0.validator.address == balance.validatorAddress }
        }

        if hasPending {
            log("Has pending transaction for \(balance)")
        }

        return hasPending
    }
}

// MARK: - Private

private extension CommonStakingPendingTransactionsRepository {
    func loadPendingTransactions() {
        do {
            cache = try storage.value(for: .pendingStakingTransactions) ?? []
            checkOldRecords()
        } catch {
            log("Couldn't get the staking transactions list from the storage with error \(error)")
        }
    }

    func checkOldRecords() {
        guard let deadline = Calendar.current.date(byAdding: .day, value: -1, to: Date())?.date else {
            return
        }

        // Leave the records only newer then deadline(24 hours ago)
        cache = cache.filter { $0.date > deadline }
    }

    func saveChanges() {
        do {
            try storage.store(value: cache, for: .pendingStakingTransactions)
        } catch {
            log("Failed to save changes in storage. Reason: \(error)")
        }
    }

    func compare(_ record: StakingPendingTransactionRecord, _ balance: StakingBalanceInfo, by types: [CompareType]) -> Bool {
        let equals = types.map { type in
            switch type {
            case .validator:
                record.validator.address == balance.validatorAddress
            case .amount:
                record.amount == balance.amount
            case .type(let array):
                array.contains(where: { $0 == balance.balanceType })
            }
        }

        return equals.allConforms { $0 }
    }

    func mapToStakingPendingTransactionRecord(action: StakingAction, validator: ValidatorInfo?) -> StakingPendingTransactionRecord {
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

        let validator = StakingPendingTransactionRecord.Validator(
            address: validator?.address ?? action.validator,
            name: validator?.name,
            iconURL: validator?.iconURL,
            apr: validator?.apr
        )

        return StakingPendingTransactionRecord(amount: action.amount, validator: validator, type: type, date: Date())
    }

    func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Staking Repository] \(message())")
    }
}

private extension CommonStakingPendingTransactionsRepository {
    enum CompareType {
        case validator
        case amount
        case type([BalanceType])
    }
}
