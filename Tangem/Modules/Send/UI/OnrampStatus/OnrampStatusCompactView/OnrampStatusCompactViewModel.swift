//
//  OnrampStatusCompactViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 28.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class OnrampStatusCompactViewModel: ObservableObject {
    @Published var statusesList: [PendingExpressTxStatusRow.StatusRowData] = []

    private let pendingTransactionsManager: PendingExpressTransactionsManager
    private var bag: Set<AnyCancellable> = []

    init(input: OnrampStatusInput, pendingTransactionsManager: PendingExpressTransactionsManager) {
        self.pendingTransactionsManager = pendingTransactionsManager

        // Fill the placeholder because the transaction may hasn't loaded yet
        initialSetupView()
        bind(input: input)
    }
}

// MARK: - Private

private extension OnrampStatusCompactViewModel {
    func bind(input: OnrampStatusInput) {
        Publishers.CombineLatest(
            pendingTransactionsManager.pendingTransactionsPublisher,
            input.expressTransactionId
        )
        .compactMap { pendingTransactions, transactionId in
            pendingTransactions.first(where: { $0.expressTransactionId == transactionId })
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] pendingTransaction in
            self?.updateUI(pendingTransaction: pendingTransaction)
        }
        .store(in: &bag)
    }

    func updateUI(pendingTransaction: PendingTransaction) {
        let converter = PendingExpressTransactionsConverter()
        let (list, _) = converter.convertToStatusRowDataList(for: pendingTransaction)
        statusesList = list
    }

    func initialSetupView() {
        statusesList = [
            .init(
                title: PendingExpressTransactionStatus.awaitingDeposit.activeStatusTitle,
                state: .loader
            ),
            .init(
                title: PendingExpressTransactionStatus.confirming.activeStatusTitle,
                state: .empty
            ),
            .init(
                title: PendingExpressTransactionStatus.buying.activeStatusTitle,
                state: .empty
            ),
            .init(
                title: PendingExpressTransactionStatus.sendingToUser.activeStatusTitle,
                state: .empty
            ),
        ]
    }
}
