//
//  PendingOnrampTransactionManager.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

protocol PendingOnrampTransactionsManager: PendingGenericTransactionsManager {
    var pendingTransactions: [PendingOnrampTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingOnrampTransaction], Never> { get }

    func hideTransaction(with id: String)
}

extension PendingOnrampTransactionsManager {
    var pendingGenericTransactions: [PendingTransaction] {
        pendingTransactions.map(PendingTransaction.from)
    }

    var pendingGenericTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        pendingTransactionsPublisher
            .map { transactions in
                transactions.map(PendingTransaction.from)
            }
            .eraseToAnyPublisher()
    }

    func hideGenericTransaction(with id: String) {
        hideTransaction(with: id)
    }
}

class CommonPendingOnrampTransactionsManager {
    @Injected(\.onrampPendingTransactionsRepository) private var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository

    private let userWalletId: String
    private let walletModel: WalletModel
    private let expressAPIProvider: ExpressAPIProvider

    private let pendingTransactionFactory = PendingExpressTransactionFactory()
    private let pollingService: PollingService<PendingOnrampTransaction, PendingOnrampTransaction>

    private let pendingTransactionsSubject = CurrentValueSubject<[PendingOnrampTransaction], Never>([])
    private var bag = Set<AnyCancellable>()
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(
        userWalletId: String,
        walletModel: WalletModel
    ) {
        self.userWalletId = userWalletId
        self.walletModel = walletModel
        expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        pollingService = PollingService(
            request: { [expressAPIProvider, pendingTransactionFactory] prendinTransaction in
                do {
                    let record = prendinTransaction.transactionRecord
                    let onrampTransactionStatus = try await expressAPIProvider.onrampStatus(transactionId: record.expressTransactionId)
                    let pendingTransaction = pendingTransactionFactory.buildPendingOnrampTransaction(
                        currentOnrampStatus: onrampTransactionStatus,
                        for: record
                    )
                    return pendingTransaction
                } catch {
                    return nil
                }
            },
            shouldStopPolling: { pendingTransaction in
                pendingTransaction.transactionRecord.transactionStatus.isTerminated
            },
            hasChanges: { pendingTransactionA, pendingTransactionB in
                pendingTransactionA.transactionRecord.transactionStatus != pendingTransactionB.transactionRecord.transactionStatus
            },
            pollingInterval: Constants.statusUpdateTimeout
        )

        bind()
    }

    private func bind() {
        onrampPendingTransactionsRepository.transactionsPublisher
            .withWeakCaptureOf(self)
            .map { manager, txRecords in
                manager.filterRelatedTokenTransactions(list: txRecords)
            }
            .removeDuplicates()
            .map { transactions in
                let factory = PendingExpressTransactionFactory()
                let savedPendingTransactions = transactions.map(factory.buildPendingOnrampTransaction(for:))
                return savedPendingTransactions
            }
            .withPrevious()
            .sink { [pollingService] previous, current in
                let shouldForceReload = previous?.count ?? 0 != current.count
                pollingService.startPolling(requests: current, force: shouldForceReload)
            }
            .store(in: &bag)

        pollingService
            .resultPublisher
            .map { $0.map(\.data) }
            .assign(to: \.pendingTransactionsSubject.value, on: self, ownership: .weak)
            .store(in: &bag)

        pollingService.resultPublisher
            .map { responses in
                responses.compactMap { result in
                    if result.hasChanges {
                        return result.data.transactionRecord
                    }
                    return nil
                }
            }
            .sink { [onrampPendingTransactionsRepository] transactionsToUpdateInRepository in
                onrampPendingTransactionsRepository.updateItems(transactionsToUpdateInRepository)
            }
            .store(in: &bag)
    }

    private func filterRelatedTokenTransactions(list: [OnrampPendingTransactionRecord]) -> [OnrampPendingTransactionRecord] {
        list.filter { record in
            guard !record.isHidden else {
                return false
            }

            // We should show only `supportStatusTracking` transaction on UI
            guard record.provider.type.supportStatusTracking else {
                return false
            }

            guard record.userWalletId == userWalletId else {
                return false
            }

            return record.destinationTokenTxInfo.tokenItem == tokenItem
        }
    }
}

extension CommonPendingOnrampTransactionsManager: PendingOnrampTransactionsManager {
    var pendingTransactions: [PendingOnrampTransaction] {
        pendingTransactionsSubject.value
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingOnrampTransaction], Never> {
        pendingTransactionsSubject.eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {
        onrampPendingTransactionsRepository.hideSwapTransaction(with: id)
    }
}

extension CommonPendingOnrampTransactionsManager {
    enum Constants {
        static let statusUpdateTimeout: Double = 10
    }
}
