//
//  TransactionsListView.swift
//  Tangem
//
//  Created by Andrew Son on 08/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionListItem: Hashable, Identifiable {
    var id: Int { hashValue }

    let header: String
    let items: [TransactionRecord]
}

struct TransactionsListView: View {
    let state: State

    var body: some View {
        VStack {
            header

            content
        }
        .padding(.top, 13)
        .padding([.horizontal, .bottom], 16)
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Text(Localization.transactionHistoryTitle)
                .style(
                    Fonts.Bold.footnote,
                    color: Colors.Text.tertiary
                )
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loaded(let items):
            transactionsContent(transactionItems: items)
        case .error:
            errorContent
        case .loading:
            loadingContent
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        VStack(spacing: 10) {
            ForEach(0 ... 2) { _ in
                TransactionViewPlaceholder()
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack {
            Text(Localization.transactionHistoryErrorFailedToLoad)
                .style(
                    Fonts.Bold.footnote,
                    color: Colors.Text.tertiary
                )
        }
        .padding(.top, 93)
        .padding(.bottom, 126)
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            VStack(spacing: 20) {
                Assets.coinSlot.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)

                Text(Localization.transactionHistoryEmptyTransactions)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }
            .padding(.top, 53)
            .padding(.bottom, 70)
        } else {
            ForEach(transactionItems, id: \.id) { item in
                Section {
                    VStack(spacing: 10) {
                        ForEach(item.items, id: \.id) { record in
                            TransactionView(transactionRecord: record)
                        }
                    }
                } header: {
                    HStack {
                        Text(item.header)
                            .style(
                                Fonts.Regular.footnote,
                                color: Colors.Text.tertiary
                            )
                            .padding(.vertical, 12)
                        Spacer()
                    }
                }
            }
        }
    }
}

extension TransactionsListView {
    enum State {
        case loading
        case error(Error)
        case loaded([TransactionListItem])
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static let listItems = [
        TransactionListItem(
            header: "Today",
            items: [
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
        TransactionListItem(
            header: "Yesterday",
            items: [
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
        TransactionListItem(
            header: "02.05.23",
            items: [
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
    ]

    static var previews: some View {
        ScrollView {
            LazyVStack {
                TransactionsListView(state: .loaded([]))
                TransactionsListView(state: .error(""))
                TransactionsListView(state: .loading)
            }
        }
        .background(Colors.Background.secondary)
        .padding(.horizontal, 16)

        ScrollView {
            LazyVStack {
                TransactionsListView(state: .loaded(listItems))
            }
        }
        .padding(.horizontal, 16)
    }
}
