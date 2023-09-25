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
            viewModel.icon
                .renderingMode(.template)
                .foregroundColor(viewModel.iconColor)
                .padding(10)
                .background(viewModel.iconBackgroundColor)
                .cornerRadiusContinuous(20)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(viewModel.name)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    if viewModel.inProgress {
                        Assets.pendingTxIndicator.image
                    }

                    Spacer()

                    if let amount = viewModel.formattedAmount {
                        SensitiveText(amount)
                            .style(Fonts.Regular.subheadline, color: viewModel.amountTextColor)
                    }
                }

                HStack(spacing: 6) {
                    Text(viewModel.localizeDestination)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(viewModel.subtitleText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

struct TransactionView_Previews: PreviewProvider {
    static let previewViewModels: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "10:45",
            amount: "443 wxDAI",
            isOutgoing: false,
            transactionType: .transfer,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "05:10",
            amount: "50 wxDAI",
            isOutgoing: false,
            transactionType: .transfer,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"),
            timeFormatted: "00:04",
            amount: "0 wxDAI",
            isOutgoing: true,
            transactionType: .approval,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"),
            timeFormatted: "15:00",
            amount: "15 wxDAI",
            isOutgoing: true,
            transactionType: .swap,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "16:23",
            amount: "0.000000532154 ETH",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "16:23",
            amount: "0.532154 USDT",
            isOutgoing: true,
            transactionType: .swap,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "18:32",
            amount: "0.0012 ETH",
            isOutgoing: true,
            transactionType: .approval,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "18:32",
            amount: "0.0012 ETH",
            isOutgoing: true,
            transactionType: .approval,
            status: .inProgress
        ),
    ]

    static var previews: some View {
        VStack {
            ForEach(previewViewModels) {
                TransactionView(viewModel: $0)
            }
        }
        .padding()
    }
}
