//
//  CommonExpressPendingTransactionRepository.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class CommonExpressPendingTransactionRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonExpressPendingTransactionRepository.lockQueue")

    private var pendingTransactionSubject = CurrentValueSubject<[ExpressPendingTransactionRecord], Never>([])

    init() {
        loadPendingTransactions()
    }

    private func loadPendingTransactions() {
        do {
            pendingTransactionSubject.value = try storage.value(for: .pendingExpressTransactions) ?? []
        } catch {
            log("Couldn't get the express transactions list from the storage with error \(error)")
        }
    }

    private func addRecordIfNeeded(_ record: ExpressPendingTransactionRecord) {
        if pendingTransactionSubject.value.contains(where: { $0.expressTransactionId == record.expressTransactionId }) {
            return
        }

        pendingTransactionSubject.value.append(record)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try storage.store(value: pendingTransactionSubject.value, for: .pendingExpressTransactions)
        } catch {
            log("Failed to save changes in storage. Reason: \(error)")
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Express Tx Repository] \(message())")
    }
}

extension CommonExpressPendingTransactionRepository: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] {
        pendingTransactionSubject.value
    }

    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> {
        pendingTransactionSubject
            .eraseToAnyPublisher()
    }

    func swapTransactionDidSend(_ txData: SentExpressTransactionData, userWalletId: String) {
        let expressPendingTransactionRecord = ExpressPendingTransactionRecord(
            userWalletId: userWalletId,
            expressTransactionId: txData.expressTransactionData.expressTransactionId,
            destinationTokenTxInfo: .init(
                tokenItem: txData.destination.tokenItem,
                amountString: txData.expressTransactionData.toAmount.stringValue,
                isCustom: txData.destination.isCustom
            ),
            provider: .init(provider: txData.provider),
            externalTxId: txData.expressTransactionData.externalTxId,
            externalTxURL: txData.expressTransactionData.externalTxUrl,
            date: txData.date,
            expressSpecific: .init(
                transactionType: .type(from: txData.expressTransactionData.transactionType),
                transactionHash: txData.hash,
                sourceTokenTxInfo: .init(
                    tokenItem: txData.source.tokenItem,
                    amountString: txData.expressTransactionData.fromAmount.stringValue,
                    isCustom: txData.source.isCustom
                ),
                feeString: txData.fee.stringValue
            ),
            onrampSpecific: nil,
            isHidden: false,
            transactionStatus: .awaitingDeposit
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(expressPendingTransactionRecord)
        }
    }

    func onrampTransactionDidSend(_ txData: SentOnrampTransactionData, userWalletId: String) {
        let expressPendingTransactionRecord = ExpressPendingTransactionRecord(
            userWalletId: userWalletId,
            expressTransactionId: txData.txId,
            destinationTokenTxInfo: .init(
                tokenItem: txData.destinationTokenItem,
                amountString: txData.onrampTransactionData.toAmount ?? "",
                isCustom: false
            ),
            provider: .init(provider: txData.provider.provider),
            externalTxId: txData.onrampTransactionData.externalTxId,
            externalTxURL: nil,
            date: txData.date,
            expressSpecific: nil,
            onrampSpecific: .init(
                fromAmount: txData.onrampTransactionData.fromAmount,
                fromCurrencyCode: txData.onrampTransactionData.fromCurrencyCode
            ),
            isHidden: false,
            transactionStatus: .awaitingDeposit,
            refundedTokenItem: nil
        )

        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(expressPendingTransactionRecord)
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

    func updateItems(_ items: [ExpressPendingTransactionRecord]) {
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

extension CommonExpressPendingTransactionRepository: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
