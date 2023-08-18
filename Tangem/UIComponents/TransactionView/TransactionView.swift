//
//  TransactionView.swift
//  Tangem
//
//  Created by Andrew Son on 08/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionView: View {
    let viewModel: TransactionViewModel

    var body: some View {
        HStack(spacing: 12) {
            txTypeIcon
                .renderingMode(.template)
                .foregroundColor(viewModel.status.iconColor)
                .padding(10)
                .background(viewModel.status.iconBackgroundColor)
                .cornerRadiusContinuous(20)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(viewModel.transactionType.name)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    if case .inProgress = viewModel.status {
                        Assets.pendingTxIndicator.image
                    }

                    Spacer()

                    Text(viewModel.transferAmount)
                        .style(Fonts.Regular.subheadline, color: viewModel.transactionType.amountTextColor)
                }

                HStack(spacing: 6) {
                    Text(viewModel.destination)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    Text(subtitleText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }

    private var txTypeIcon: Image {
        switch viewModel.transactionType {
        case .receive:
            return Assets.arrowDownMini.image
        case .send:
            return Assets.arrowUpMini.image
        case .swap:
            return Assets.exchangeMini.image
        case .approval:
            return Assets.approve.image
        }
    }

    private var subtitleText: String {
        switch viewModel.status {
        case .confirmed:
            return viewModel.timeFormatted ?? "-"
        case .inProgress:
            return Localization.transactionHistoryTxInProgress
        }
    }
}

struct TransactionView_Previews: PreviewProvider {
    static func destination(for transactionType: TransactionViewModel.TransactionType, address: String) -> String {
        transactionType.localizeDestination(for: address)
    }

    static let incomingInProgressRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .receive, address: "0x01230...3feed"),
        timeFormatted: "10:45",
        transferAmount: "+443 wxDAI",
        transactionType: .receive,
        status: .inProgress
    )

    static let incomingConfirmedRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .receive, address: "0x01230...3feed"),
        timeFormatted: "05:10",
        transferAmount: "+50 wxDAI",
        transactionType: .receive,
        status: .confirmed
    )

    static let outgoingInProgressRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .receive, address: "0x012...baced"),
        timeFormatted: "00:04",
        transferAmount: "-0.5 wxDAI",
        transactionType: .send,
        status: .inProgress
    )

    static let outgoingConfirmedRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .receive, address: "0x0123...baced"),
        timeFormatted: "15:00",
        transferAmount: "-15 wxDAI",
        transactionType: .send,
        status: .confirmed
    )

    static let incomingSwapRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .swap(type: .buy), address: "0x0123...baced"),
        timeFormatted: "16:23",
        transferAmount: "+0.000000532154 ETH",
        transactionType: .swap(type: .buy),
        status: .inProgress
    )

    static let outgoingSwapRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .swap(type: .sell), address: "0x0123...baced"),
        timeFormatted: "16:23",
        transferAmount: "-0.532154 USDT",
        transactionType: .swap(type: .sell),
        status: .confirmed
    )

    static let approveConfirmedRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .approval, address: "0x0123...baced"),
        timeFormatted: "18:32",
        transferAmount: "-0.0012 ETH",
        transactionType: .approval,
        status: .confirmed
    )

    static let approveInProgressRecord = TransactionViewModel(
        id: UUID().uuidString,
        destination: destination(for: .approval, address: "0x0123...baced"),
        timeFormatted: "18:32",
        transferAmount: "-0.0012 ETH",
        transactionType: .approval,
        status: .inProgress
    )

    static var previews: some View {
        VStack {
            TransactionView(viewModel: incomingInProgressRecord)
            TransactionView(viewModel: incomingConfirmedRecord)
            TransactionView(viewModel: outgoingInProgressRecord)
            TransactionView(viewModel: outgoingConfirmedRecord)
            TransactionView(viewModel: incomingSwapRecord)
            TransactionView(viewModel: outgoingSwapRecord)
            TransactionView(viewModel: approveInProgressRecord)
            TransactionView(viewModel: approveConfirmedRecord)
        }
        .padding()
    }
}
