//
//  CommonOnrampPendingTransactionRepository.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class CommonOnrampPendingTransactionRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonOnrampPendingTransactionRepository.lockQueue")

    private var pendingTransactionSubject = CurrentValueSubject<[OnrampPendingTransactionRecord], Never>([])

    init() {
        loadPendingTransactions()
    }

    private func loadPendingTransactions() {
        do {
            pendingTransactionSubject.value = try storage.value(for: .pendingOnrampTransactions) ?? []
        } catch {
            log("Couldn't get the express transactions list from the storage with error \(error)")
        }
    }

    private func addRecordIfNeeded(_ redirectDataWithId: OnrampPendingTransactionRecord) {
        if pendingTransactionSubject.value.contains(where: { $0.txId == redirectDataWithId.txId }) {
            return
        }

        pendingTransactionSubject.value.append(redirectDataWithId)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try storage.store(value: pendingTransactionSubject.value, for: .pendingOnrampTransactions)
        } catch {
            log("Failed to save changes in storage. Reason: \(error)")
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Onramp Tx Repository] \(message())")
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
            txId: txData.txId,
            provider: .init(provider: txData.provider.provider),
            fromAmount: Decimal(stringValue: txData.onrampTransactionData.fromAmount).flatMap { $0 / 100 } ?? .zero, // TODO: Maybe some better way?
            fromCurrencyCode: txData.onrampTransactionData.fromCurrencyCode,
            destinationTokenTxInfo: .init(
                tokenItem: txData.destinationTokenItem,
                amountString: txData.onrampTransactionData.toAmount ?? "", // TODO: Should not be nullable
                isCustom: false
            ),
            transactionStatus: .awaitingDeposit
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(onrampPendingTransactionRecord)
        }
    }

    func updateItems(_ items: [OnrampPendingTransactionRecord]) {
        if items.isEmpty {
            return
        }

        lockQueue.async { [weak self] in
            guard let self else { return }

            let transactionsToUpdate = items.toDictionary(keyedBy: \.txId)
            var hasChanges = false
            var pendingTransactions = pendingTransactionSubject.value
            for (index, item) in pendingTransactions.indexed() {
                guard let updatedTransaction = transactionsToUpdate[item.txId] else {
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
