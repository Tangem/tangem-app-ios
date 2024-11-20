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

    private var pendingTransactionSubject = CurrentValueSubject<[OnrampRedirectDataWithId], Never>([])

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

    private func addRecordIfNeeded(_ redirectDataWithId: OnrampRedirectDataWithId) {
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
    var transactions: [OnrampRedirectDataWithId] {
        pendingTransactionSubject.value
    }

    var transactionsPublisher: AnyPublisher<[OnrampRedirectDataWithId], Never> {
        pendingTransactionSubject
            .eraseToAnyPublisher()
    }

    func onrampTransactionDidSend(_ redirectDataWithId: OnrampRedirectDataWithId) {
        lockQueue.async { [weak self] in
            self?.addRecordIfNeeded(redirectDataWithId)
        }
    }

    func updateItems(_ items: [OnrampRedirectDataWithId]) {
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
