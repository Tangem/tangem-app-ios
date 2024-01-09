//
//  PendingExpressTransactionsConverter.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransactionsConverter {
    func convertToTokenDetailsPendingTxInfo(_ records: [PendingExpressTransaction], tapAction: @escaping (String) -> Void) -> [PendingExpressTransactionView.Info] {
        let iconBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        return records.compactMap {
            let record = $0.transactionRecord
            let sourceTokenItem = record.sourceTokenTxInfo.tokenItem
            let destinationTokenItem = record.destinationTokenTxInfo.tokenItem
            let state: PendingExpressTransactionView.State
            switch $0.transactionRecord.transactionStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done, .refunded:
                state = .inProgress
            case .failed, .canceled:
                state = .error
            case .verificationRequired:
                state = .warning
            }

            return .init(
                id: record.expressTransactionId,
                providerName: record.provider.name,
                sourceIconInfo: iconBuilder.build(from: sourceTokenItem, isCustom: record.sourceTokenTxInfo.isCustom),
                sourceAmountText: balanceFormatter.formatCryptoBalance(record.sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol),
                destinationIconInfo: iconBuilder.build(from: destinationTokenItem, isCustom: record.destinationTokenTxInfo.isCustom),
                destinationCurrencySymbol: destinationTokenItem.currencySymbol,
                state: state,
                action: tapAction
            )
        }
    }

    func convertToStatusRowDataList(for pendingTransaction: PendingExpressTransaction) -> (list: [PendingExpressTransactionStatusRow.StatusRowData], currentIndex: Int) {
        let statuses = pendingTransaction.statuses
        let currentStatusIndex = statuses.firstIndex(of: pendingTransaction.transactionRecord.transactionStatus) ?? 0

        return (statuses.indexed().map { index, status in
            convertToStatusRowData(
                index: index,
                status: status,
                currentStatusIndex: currentStatusIndex,
                currentStatus: pendingTransaction.transactionRecord.transactionStatus,
                lastStatusIndex: statuses.count - 1
            )
        }, currentStatusIndex)
    }

    private func convertToStatusRowData(
        index: Int,
        status: PendingExpressTransactionStatus,
        currentStatusIndex: Int,
        currentStatus: PendingExpressTransactionStatus,
        lastStatusIndex: Int
    ) -> PendingExpressTransactionStatusRow.StatusRowData {
        let isFinished = !currentStatus.isTransactionInProgress
        if isFinished {
            // Always display cross for failed state
            switch status {
            case .failed:
                return .init(title: status.passedStatusTitle, state: .cross(passed: true))
            case .canceled:
                return .init(title: status.passedStatusTitle, state: .cross(passed: false))
            default:
                return .init(title: status.passedStatusTitle, state: .checkmark)
            }
        }

        let isCurrentStatus = index == currentStatusIndex
        let isPendingStatus = index > currentStatusIndex

        let title: String = isCurrentStatus ? status.activeStatusTitle : isPendingStatus ? status.pendingStatusTitle : status.passedStatusTitle
        var state: PendingExpressTransactionStatusRow.State = isCurrentStatus ? .loader : isPendingStatus ? .empty : .checkmark

        switch status {
        case .failed:
            state = .cross(passed: false)
        case .refunded:
            // Refunded state is the final state and it can't be pending (with loader)
            state = isFinished ? .checkmark : .empty
        case .verificationRequired:
            state = .exclamationMark
        case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done, .canceled:
            break
        }

        return .init(title: title, state: state)
    }
}
