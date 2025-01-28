//
//  CommonOnrampPendingTransactionRepository.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class CommonOnrampPendingTransactionRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonOnrampPendingTransactionRepository.lockQueue")

    private let pendingTransactionSubject = CurrentValueSubject<[OnrampPendingTransactionRecord], Never>([])

    init() {
        loadPendingTransactions()
    }

    private func loadPendingTransactions() {
        do {
            pendingTransactionSubject.value = try storage.value(for: .pendingOnrampTransactions) ?? []
        } catch {
            AppLog.error("Couldn't get the onramp transactions list from the storage", error: error)
        }
    }

    private func addRecordIfNeeded(_ record: OnrampPendingTransactionRecord) {
        if pendingTransactionSubject.value.contains(where: { $0.expressTransactionId == record.expressTransactionId }) {
            return
        }

        pendingTransactionSubject.value.append(record)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try storage.store(value: pendingTransactionSubject.value, for: .pendingOnrampTransactions)
        } catch {
            AppLog.error("Failed to save changes in storage.", error: error)
        }
    }
}

extension CommonOnrampPendingTransactionRepository: OnrampPendingTransactionRepository {
    var transactions: [OnrampPendingTransactionRecord] {
        pendingTransactionSubject.value
    }

    var transactionsPublisher: AnyPublisher<[OnrampPendingTransactionRecord], Never> {
        pendingTransactionSubject
            .eraseToAnyPublisher()
    }

    func onrampTransactionDidSend(_ txData: SentOnrampTransactionData, userWalletId: String) {
        let onrampPendingTransactionRecord = OnrampPendingTransactionRecord(
            userWalletId: userWalletId,
            expressTransactionId: txData.txId,
            fromAmount: txData.fromAmount,
            fromCurrencyCode: txData.fromCurrencyCode,
            destinationTokenTxInfo: .init(
                tokenItem: txData.destinationTokenItem,
                amountString: "",
                isCustom: false
            ),
            provider: .init(provider: txData.provider),
            date: txData.date,
            externalTxId: txData.externalTxId,
            externalTxURL: nil,
            isHidden: false,
            transactionStatus: .awaitingDeposit
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(onrampPendingTransactionRecord)
        }
    }

    func hideSwapTransaction(with id: String) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            guard let index = pendingTransactionSubject.value.firstIndex(where: { $0.expressTransactionId == id }) else {
                return
            }

            pendingTransactionSubject.value[index].isHidden = true
            saveChanges()
        }
    }

    func updateItems(_ items: [OnrampPendingTransactionRecord]) {
        if items.isEmpty {
            return
        }

        lockQueue.async { [weak self] in
            guard let self else { return }

            let transactionsToUpdate = items.toDictionary(keyedBy: \.expressTransactionId)
            var hasChanges = false
            var pendingTransactions = pendingTransactionSubject.value
            for (index, item) in pendingTransactions.indexed() {
                guard let updatedTransaction = transactionsToUpdate[item.expressTransactionId] else {
                    continue
                }

                pendingTransactions[index] = updatedTransaction
                hasChanges = true
            }

            guard hasChanges else {
                return
            }

            pendingTransactionSubject.value = pendingTransactions
            saveChanges()
        }
    }
}
