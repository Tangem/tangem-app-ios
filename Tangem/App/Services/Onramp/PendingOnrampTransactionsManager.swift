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
    var pendingTransactions: [OnrampTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[OnrampTransaction], Never> { get }
}

final class CommonPendingOnrampTransactionsManager {
    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository

    private let userWalletId: String
    private let walletModel: WalletModel
    private let expressAPIProvider: ExpressAPIProvider

    private let transactionsInProgressSubject = CurrentValueSubject<[OnrampTransaction], Never>([])

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    private var transactionsScheduledForUpdate: [OnrampTransaction] = []
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
            .map { transactions in
                transactions.map { transaction in
                    OnrampTransaction(
                        txId: transaction.txId,
                        providerId: transaction.redirectData.providerId,
                        payoutAddress: "",
                        status: .created,
                        failReason: nil,
                        externalTxId: "",
                        externalTxUrl: nil,
                        payoutHash: nil,
                        createdAt: Date().ISO8601Format(),
                        fromCurrencyCode: transaction.redirectData.fromCurrencyCode,
                        fromAmount: transaction.redirectData.fromAmount,
                        toContractAddress: transaction.redirectData.toContractAddress,
                        toNetwork: transaction.redirectData.toNetwork,
                        toDecimals: transaction.redirectData.toDecimals,
                        toAmount: transaction.redirectData.toAmount,
                        toActualAmount: transaction.redirectData.toAmount,
                        paymentMethod: transaction.redirectData.paymentMethod,
                        countryCode: transaction.redirectData.countryCode
                    )
                }
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

    private func filterRelatedTokenTransactions(list: [OnrampRedirectDataWithId]) -> [OnrampRedirectDataWithId] {
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
            record.redirectData.toNetwork.lowercased() == tokenItem.networkName.lowercased()
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
                var transactionsToSchedule = [OnrampTransaction]()
                var transactionsInProgress = [OnrampTransaction]()
                var transactionsToUpdateInRepository = [OnrampRedirectDataWithId]()

                for pendingTransaction in pendingTransactionsToRequest {
                    // We have not any sense to update the terminated status
                    guard !pendingTransaction.status.isTerminated else {
                        transactionsInProgress.append(pendingTransaction)
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    guard let loadedPendingTransaction = await self?.loadPendingTransactionStatus(for: pendingTransaction.txId) else {
                        // If received error from backend and transaction was already displayed on TokenDetails screen
                        // we need to send previously received transaction, otherwise it will hide on TokenDetails
                        if let previousResult = self?.transactionsInProgressSubject.value.first(where: { $0.txId == pendingTransaction.txId }) {
                            transactionsInProgress.append(previousResult)
                        }
                        transactionsToSchedule.append(pendingTransaction)
                        continue
                    }

                    // We need to send finished transaction one more time to properly update status on bottom sheet
                    transactionsInProgress.append(loadedPendingTransaction)

                    if pendingTransaction.status != loadedPendingTransaction.status {
                        // TODO: Uncommend and fix
//                        transactionsToUpdateInRepository.append(loadedPendingTransaction)
                    }

                    // If transaction is done we have to update balance
                    if loadedPendingTransaction.status.isDone {
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

    private func loadPendingTransactionStatus(for transactionId: String) async -> OnrampTransaction? {
        do {
            return try await expressAPIProvider.onrampStatus(transactionId: transactionId)
        } catch {
            return nil
        }
    }
}

extension CommonPendingOnrampTransactionsManager: PendingOnrampTransactionsManager {
    var pendingTransactions: [OnrampTransaction] {
        transactionsInProgressSubject.value
    }

    var pendingTransactionsPublisher: AnyPublisher<[OnrampTransaction], Never> {
        transactionsInProgressSubject.eraseToAnyPublisher()
    }
}

extension CommonPendingOnrampTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
