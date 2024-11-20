//
//  PendingOnrampTransactionsManager.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol PendingOnrampTransactionsManager: AnyObject {
    var pendingTransactions: [PendingOnrampTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingOnrampTransaction], Never> { get }
}

final class CommonPendingOnrampTransactionsManager {
    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository

    private let userWalletId: String
    private let walletModel: WalletModel
    private let expressAPIProvider: ExpressAPIProvider

    private let transactionsInProgressSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])
    private let pendingTransactionFactory = PendingOnrampTransactionFactory()

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    private var transactionsScheduledForUpdate: [PendingOnrampTransaction] = []
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(
        userWalletId: String,
        walletModel: WalletModel
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
        expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        bind()
    }

    private func cancelTask() {
        if updateTask != nil {
            updateTask?.cancel()
            updateTask = nil
        }
    }

    private func bind() {
        onrampPendingTransactionsRepository
            .transactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, transactions in
                manager.filterRelatedTokenTransactions(list: transactions)
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { manager, records in
                records.map(manager.pendingTransactionFactory.buildPendingOnrampTransaction)
            }
            .withWeakCaptureOf(self)
            .sink { manager, transactions in
                let shouldForceReload = manager.transactionsScheduledForUpdate.count != transactions.count
                manager.transactionsScheduledForUpdate = transactions
                manager.transactionsInProgressSubject.send(transactions)
                manager.updateTransactionsStatuses(forceReload: shouldForceReload)
            }
            .store(in: &bag)
    }

    deinit {
        cancelTask()
    }

    private func filterRelatedTokenTransactions(list: [OnrampPendingTransactionRecord]) -> [OnrampPendingTransactionRecord] {
        list.filter { record in
//            guard !record.isHidden else {
//                return false
//            }
//
//            // We should show only `supportStatusTracking` transaction on UI
//            guard record.provider.type.supportStatusTracking else {
//                return false
//            }
//
//            guard record.userWalletId == userWalletId else {
//                return false
//            }
//
//
//
//            let isSame = record.sourceTokenTxInfo.tokenItem == tokenItem
//                || record.destinationTokenTxInfo.tokenItem == tokenItem
//
//            return isSame
            record.destinationTokenTxInfo.tokenItem == tokenItem
        }
    }

    private func updateTransactionsStatuses(forceReload: Bool) {
        if !forceReload, updateTask != nil {
            return
        }

        cancelTask()

        if transactionsScheduledForUpdate.isEmpty {
            return
        }
        let pendingTransactionsToRequest = transactionsScheduledForUpdate
        transactionsScheduledForUpdate = []

        updateTask = Task { [weak self] in
            do {
                var transactionsToSchedule = [PendingOnrampTransaction]()
                var transactionsInProgress = [PendingOnrampTransaction]()
                var transactionsToUpdateInRepository = [OnrampPendingTransactionRecord]()

                for pendingTransaction in pendingTransactionsToRequest {
                    let record = pendingTransaction.transactionRecord

                    // We have not any sense to update the terminated status
                    guard !record.transactionStatus.isTerminated else {
                        transactionsInProgress.append(pendingTransaction)
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    guard let loadedPendingTransaction = await self?.loadPendingTransactionStatus(for: record) else {
                        // If received error from backend and transaction was already displayed on TokenDetails screen
                        // we need to send previously received transaction, otherwise it will hide on TokenDetails
                        if let previousResult = self?.transactionsInProgressSubject.value.first(where: { $0.transactionRecord.txId == record.txId }) {
                            transactionsInProgress.append(previousResult)
                        }
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    // We need to send finished transaction one more time to properly update status on bottom sheet
                    transactionsInProgress.append(loadedPendingTransaction)

                    if pendingTransaction.transactionRecord.transactionStatus != loadedPendingTransaction.transactionRecord.transactionStatus {
                        // TODO: Uncommend and fix
                        transactionsToUpdateInRepository.append(loadedPendingTransaction.transactionRecord)
                    }

                    // If transaction is done we have to update balance
                    if loadedPendingTransaction.transactionRecord.transactionStatus.isDone {
                        self?.walletModel.update(silent: true)
                    }

                    transactionsToSchedule.append(loadedPendingTransaction)
                    try Task.checkCancellation()
                }

                try Task.checkCancellation()

                self?.transactionsScheduledForUpdate = transactionsToSchedule
                self?.transactionsInProgressSubject.send(transactionsInProgress)

                if !transactionsToUpdateInRepository.isEmpty {
                    self?.onrampPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
                }

                try Task.checkCancellation()

                try await Task.sleep(seconds: Constants.statusUpdateTimeout)

                try Task.checkCancellation()

                self?.updateTransactionsStatuses(forceReload: true)
            } catch {
                if error is CancellationError || Task.isCancelled {
                    return
                }

                self?.transactionsScheduledForUpdate = pendingTransactionsToRequest
                self?.updateTransactionsStatuses(forceReload: false)
            }
        }
    }

    private func loadPendingTransactionStatus(for transactionRecord: OnrampPendingTransactionRecord) async -> PendingOnrampTransaction? {
        do {
            let onrampTransaction = try await expressAPIProvider.onrampStatus(transactionId: transactionRecord.txId)
            let pendingTransaction = pendingTransactionFactory.buildPendingOnrampTransaction(
                currentOnrampStatus: onrampTransaction.status,
                for: transactionRecord
            )
            return pendingTransaction
        } catch {
            return nil
        }
    }
}

extension CommonPendingOnrampTransactionsManager: PendingOnrampTransactionsManager {
    var pendingTransactions: [PendingOnrampTransaction] {
        transactionsInProgressSubject.value
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingOnrampTransaction], Never> {
        transactionsInProgressSubject.eraseToAnyPublisher()
    }
}

extension CommonPendingOnrampTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
