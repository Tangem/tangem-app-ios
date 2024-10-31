//
//  CommonStakingPendingTransactionsRepository.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingPendingTransactionsStorage {
    func save(records: Set<StakingPendingTransactionRecord>)
    func loadRecords() -> Set<StakingPendingTransactionRecord>
}

class CommonStakingPendingTransactionsRepository {
    private let storage: StakingPendingTransactionsStorage
    private let logger: Logger

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonStakingPendingTransactionsRepository.lockQueue")
    private var cachedRecords: CurrentValueSubject<Set<StakingPendingTransactionRecord>, Never> = .init([])
    private var savingSubscription: AnyCancellable?

    init(storage: StakingPendingTransactionsStorage, logger: Logger) {
        self.storage = storage
        self.logger = logger

        loadPendingTransactions()
        bind()
    }
}

// MARK: - StakingPendingTransactionsRepository

extension CommonStakingPendingTransactionsRepository: StakingPendingTransactionsRepository {
    var records: Set<StakingPendingTransactionRecord> { cachedRecords.value }

    var recordsPublisher: AnyPublisher<Set<StakingPendingTransactionRecord>, Never> {
        cachedRecords.removeDuplicates().eraseToAnyPublisher()
    }

    func transactionDidSent(action: StakingAction, integrationId: String) {
        let record = mapToStakingPendingTransactionRecord(action: action, integrationId: integrationId)
        log("Will be add record - \(record)")

        cachedRecords.value.insert(record)
    }

    func checkIfConfirmed(balances: [StakingBalanceInfo]) {
        let records = cachedRecords.value.filter { record in
            let shouldDelete: Bool = {
                switch record.type {
                case .stake, .voteLocked, .restake:
                    balances.contains { balance in
                        compare(record, balance, by: [.validator(.some), .type([.active, .warmup])])
                    }
                case .unstake:
                    !balances.contains { balance in
                        compare(record, balance, by: [.validator(.some), .type([.active]), .amount])
                    }
                case .withdraw, .claimUnstaked:
                    !balances.contains { balance in
                        compare(record, balance, by: [.validator(.some), .type([.unstaked]), .amount])
                    }
                case .claimRewards, .restakeRewards:
                    !balances.contains { balance in
                        compare(record, balance, by: [.validator(.some), .type([.rewards]), .amount])
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

        // Submit changes only if we have them
        if records != cachedRecords.value {
            cachedRecords.send(records)
        }
    }

    func hasPending(balance: StakingBalanceInfo) -> Bool {
        let hasPending: Bool
        switch balance.balanceType {
        case .locked:
            hasPending = records.contains { record in
                compare(record, balance, by: [.amount, .validator(.none)])
            }
        case .active, .rewards, .unbonding, .warmup, .unstaked, .pending:
            hasPending = records.contains { record in
                compare(record, balance, by: [.validator(.some)])
            }
        }

        if hasPending {
            log("Has pending transaction for \(balance)")
        }

        return hasPending
    }
}

// MARK: - Private

private extension CommonStakingPendingTransactionsRepository {
    func bind() {
        savingSubscription = cachedRecords
            .receive(on: lockQueue)
            .sink(receiveValue: { [weak self] _ in
                self?.saveChanges()
            })
    }

    private func loadPendingTransactions() {
        cachedRecords.value = storage.loadRecords()
        checkOldRecords()
    }

    func checkOldRecords() {
        guard let deadline = Calendar.current.date(byAdding: .day, value: -1, to: Date())?.date else {
            return
        }

        // Leave the records only newer then deadline(24 hours ago)
        let records = cachedRecords.value.filter { $0.date > deadline }

        // Submit changes only if we have them
        if records != cachedRecords.value {
            cachedRecords.send(records)
        }
    }

    func saveChanges() {
        storage.save(records: cachedRecords.value)
    }

    func compare(_ record: StakingPendingTransactionRecord, _ balance: StakingBalanceInfo, by types: [CompareType]) -> Bool {
        let equals = types.map { type in
            switch type {
            case .validator(.some):
                // We should only compare validators with the value
                if let recordValidator = record.validator.address,
                   let balanceValidator = balance.validatorAddress {
                    return recordValidator == balanceValidator
                }

                return false
            case .validator(.none):
                return record.validator.address == .none && balance.validatorAddress == .none
            case .amount:
                return record.amount == balance.amount
            case .type(let array):
                return array.contains(where: { $0 == balance.balanceType })
            }
        }

        return equals.allConforms { $0 }
    }

    func mapToStakingPendingTransactionRecord(action: StakingAction, integrationId: String) -> StakingPendingTransactionRecord {
        let type: StakingPendingTransactionRecord.ActionType = {
            switch action.type {
            case .stake: .stake
            case .unstake: .unstake
            case .pending(.withdraw): .withdraw
            case .pending(.claimRewards): .claimRewards
            case .pending(.restakeRewards): .restakeRewards
            case .pending(.voteLocked): .voteLocked
            case .pending(.unlockLocked): .unlockLocked
            case .pending(.restake): .restake
            case .pending(.claimUnstaked): .claimUnstaked
            }
        }()

        let validator = StakingPendingTransactionRecord.Validator(
            address: action.validatorInfo?.address,
            name: action.validatorInfo?.name,
            iconURL: action.validatorInfo?.iconURL,
            apr: action.validatorInfo?.apr
        )

        return StakingPendingTransactionRecord(
            integrationId: integrationId,
            amount: action.amount,
            validator: validator,
            type: type,
            date: Date()
        )
    }

    func log<T>(_ message: @autoclosure () -> T) {
        logger.debug("[Staking Repository] \(message())")
    }
}

private extension CommonStakingPendingTransactionsRepository {
    enum CompareType {
        case validator(ValidatorType)
        case amount
        case type([StakingBalanceType])
    }

    enum ValidatorType {
        /// Has to have value
        case some
        /// Has to have not value
        case none
    }
}
