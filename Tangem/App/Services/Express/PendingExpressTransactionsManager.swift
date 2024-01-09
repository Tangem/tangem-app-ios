//
//  PendingExpressTransactionsManager.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

protocol PendingExpressTransactionsManager: AnyObject {
    var pendingTransactions: [PendingExpressTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingExpressTransaction], Never> { get }

    func hideTransaction(with id: String)
}

class CommonPendingExpressTransactionsManager {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTransactionsRepository: ExpressPendingTransactionRepository
    @Injected(\.pendingExpressTransactionAnalayticsTracker) private var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker

    private let userWalletId: String
    private let blockchainNetwork: BlockchainNetwork
    private let tokenItem: TokenItem
    private let expressAPIProvider: ExpressAPIProvider

    private let transactionsToUpdateStatusSubject = CurrentValueSubject<[ExpressPendingTransactionRecord], Never>([])
    private let transactionsInProgressSubject = CurrentValueSubject<[PendingExpressTransaction], Never>([])
    private let pendingTransactionFactory = PendingExpressTransactionFactory()

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    private var transactionsScheduledForUpdate: [PendingExpressTransaction] = []

    init(
        userWalletId: String,
        blockchainNetwork: BlockchainNetwork,
        tokenItem: TokenItem
    ) {
        self.userWalletId = userWalletId
        self.blockchainNetwork = blockchainNetwork
        self.tokenItem = tokenItem
        expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        bind()
    }

    deinit {
        print("CommonPendingExpressTransactionsManager deinit")
        cancelTask()
    }

    private func bind() {
        expressPendingTransactionsRepository.transactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, txRecords in
                manager.filterRelatedTokenTransactions(list: txRecords)
            }
            .assign(to: \.transactionsToUpdateStatusSubject.value, on: self, ownership: .weak)
            .store(in: &bag)

        transactionsToUpdateStatusSubject
            .removeDuplicates()
            .map { transactions in
                let factory = PendingExpressTransactionFactory()
                let savedPendingTransactions = transactions.map(factory.buildPendingExpressTransaction(for:))
                return savedPendingTransactions
            }
            .withWeakCaptureOf(self)
            .sink { manager, transactions in
                manager.log("Receive new transactions to update: \(transactions.count). Number of already scheduled transactions: \(manager.transactionsScheduledForUpdate.count)")
                // If transactions updated their statuses only no need to cancel currently scheduled task and force reload it
                let shouldForceReload = manager.transactionsScheduledForUpdate.count != transactions.count
                manager.transactionsScheduledForUpdate = transactions
                manager.transactionsInProgressSubject.send(transactions)
                manager.updateTransactionsStatuses(forceReload: shouldForceReload)
            }
            .store(in: &bag)
    }

    private func cancelTask() {
        log("Attempt to cancel update task")
        if updateTask != nil {
            updateTask?.cancel()
            updateTask = nil
        }
    }

    private func updateTransactionsStatuses(forceReload: Bool) {
        if !forceReload, updateTask != nil {
            log("Receive update tx status request but not force reload. Update task is still in progress. Skipping update request. Scheduled to update: \(transactionsScheduledForUpdate.count). Force reload: \(forceReload)")
            return
        }

        cancelTask()

        if transactionsScheduledForUpdate.isEmpty {
            log("No transactions scheduled for update. Skipping update request. Force reload: \(forceReload)")
            return
        }
        let pendingTransactionsToRequest = transactionsScheduledForUpdate
        transactionsScheduledForUpdate = []

        log("Setup update pending express transactions statuses task. Number of records: \(pendingTransactionsToRequest.count)")
        updateTask = Task { [weak self] in
            do {
                self?.log("Start loading pending transactions status. Number of records to request: \(pendingTransactionsToRequest.count)")
                var transactionsToSchedule = [PendingExpressTransaction]()
                var transactionsInProgress = [PendingExpressTransaction]()
                var transactionsToUpdateInRepository = [ExpressPendingTransactionRecord]()
                for pendingTransaction in pendingTransactionsToRequest {
                    let record = pendingTransaction.transactionRecord
                    guard record.transactionStatus.isTransactionInProgress else {
                        transactionsInProgress.append(pendingTransaction)
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    guard let loadedPendingTransaction = await self?.loadPendingTransactionStatus(for: record) else {
                        // If received error from backend and transaction was already displayed on TokenDetails screen
                        // we need to send previously received transaction, otherwise it will hide on TokenDetails
                        if let previousResult = self?.transactionsInProgressSubject.value.first(where: { $0.transactionRecord.expressTransactionId == record.expressTransactionId }) {
                            transactionsInProgress.append(previousResult)
                        }
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    // We need to send finished transaction one more time to properly update status on bottom sheet
                    transactionsInProgress.append(loadedPendingTransaction)

                    if record.transactionStatus != loadedPendingTransaction.transactionRecord.transactionStatus {
                        transactionsToUpdateInRepository.append(loadedPendingTransaction.transactionRecord)
                    }

                    transactionsToSchedule.append(loadedPendingTransaction)
                    try Task.checkCancellation()
                }

                try Task.checkCancellation()

                self?.transactionsScheduledForUpdate = transactionsToSchedule
                self?.transactionsInProgressSubject.send(transactionsInProgress)

                if !transactionsToUpdateInRepository.isEmpty {
                    self?.log("Some transactions updated state. Recording changes to repository. Number of updated transactions: \(transactionsToUpdateInRepository.count)")
                    // No need to continue execution, because after update new request will be performed
                    self?.expressPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
                }

                try Task.checkCancellation()

                try await Task.sleep(seconds: Constants.statusUpdateTimeout)

                try Task.checkCancellation()

                self?.log("Not all pending transactions finished. Requesting after status update after timeout for \(transactionsToSchedule.count) transaction(s)")
                self?.updateTransactionsStatuses(forceReload: true)
            } catch {
                if error is CancellationError || Task.isCancelled {
                    self?.log("Pending express txs status check task was cancelled")
                    return
                }

                self?.log("Catch error: \(error.localizedDescription). Attempting to repeat exchange status updates. Number of requests: \(pendingTransactionsToRequest.count)")
                self?.transactionsScheduledForUpdate = pendingTransactionsToRequest
                self?.updateTransactionsStatuses(forceReload: false)
            }
        }
    }

    private func filterRelatedTokenTransactions(list: [ExpressPendingTransactionRecord]) -> [ExpressPendingTransactionRecord] {
        list.filter { record in
            guard !record.isHidden else {
                return false
            }

            // We should show only CEX transaction on UI
            guard record.provider.type == .cex else {
                return false
            }

            guard record.userWalletId == userWalletId else {
                return false
            }

            let isSameBlockchain = record.sourceTokenTxInfo.blockchainNetwork == blockchainNetwork
                || record.destinationTokenTxInfo.blockchainNetwork == blockchainNetwork
            let isSameTokenItem = record.sourceTokenTxInfo.tokenItem == tokenItem
                || record.destinationTokenTxInfo.tokenItem == tokenItem

            return isSameBlockchain && isSameTokenItem
        }
    }

    private func loadPendingTransactionStatus(for transactionRecord: ExpressPendingTransactionRecord) async -> PendingExpressTransaction? {
        do {
            log("Requesting exchange status for transaction with id: \(transactionRecord.expressTransactionId)")
            let expressTransaction = try await expressAPIProvider.exchangeStatus(transactionId: transactionRecord.expressTransactionId)
            let pendingTransaction = pendingTransactionFactory.buildPendingExpressTransaction(currentExpressStatus: expressTransaction.externalStatus, for: transactionRecord)
            log("Transaction external status: \(expressTransaction.externalStatus.rawValue)")
            pendingExpressTransactionAnalyticsTracker.trackStatusForTransaction(
                with: pendingTransaction.transactionRecord.expressTransactionId,
                tokenSymbol: tokenItem.currencySymbol,
                status: pendingTransaction.transactionRecord.transactionStatus
            )
            return pendingTransaction
        } catch {
            log("Failed to load status info for transaction with id: \(transactionRecord.expressTransactionId). Error: \(error)")
            return nil
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[CommonPendingExpressTransactionsManager] \(message())")
    }
}

extension CommonPendingExpressTransactionsManager: PendingExpressTransactionsManager {
    var pendingTransactions: [PendingExpressTransaction] {
        transactionsInProgressSubject.value
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingExpressTransaction], Never> {
        transactionsInProgressSubject.eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {
        log("Hide transaction in the repository. Transaction id: \(id)")
        expressPendingTransactionsRepository.hideSwapTransaction(with: id)
    }
}

extension CommonPendingExpressTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
