//
//  PendingExpressTransactionsConverter.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransactionsConverter {
    func convertToTokenDetailsPendingTxInfo(_ records: [PendingTransaction], tapAction: @escaping (String) -> Void) -> [PendingExpressTransactionView.Info] {
        let iconBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        return records.compactMap { record in
            let title: String
            let sourceAmountText: String
            let destinationAmountText: String

            switch record.branch {
            case .swap:
                title = Localization.expressExchangeBy(record.provider.name)
            case .onramp:
                title = "Buying \(record.destinationTokenItem?.name ?? "")" // TODO: Use localization
            }

            let state: PendingExpressTransactionView.State
            switch record.transactionStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done, .refunded:
                state = .inProgress
            case .failed, .canceled, .unknown, .paused:
                state = .error
            case .verificationRequired, .awaitingHash:
                state = .warning
            }

            return .init(
                id: record.expressTransactionId,
                title: title,
                sourceIconInfo: record.sourceTokenIconInfo,
                sourceAmountText: record.sourceAmountString,
                destinationIconInfo: record.destinationTokenIconInfo,
                destinationAmountText: record.destinationAmountString,
                state: state,
                action: tapAction
            )
        }
    }

    func convertToStatusRowDataList(for pendingTransaction: PendingTransaction) -> (list: [PendingExpressTxStatusRow.StatusRowData], currentIndex: Int) {
        let statuses = pendingTransaction.statuses
        let currentStatusIndex = statuses.firstIndex(of: pendingTransaction.transactionStatus) ?? 0

        return (statuses.indexed().map { index, status in
            convertToStatusRowData(
                index: index,
                status: status,
                currentStatusIndex: currentStatusIndex,
                currentStatus: pendingTransaction.transactionStatus,
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
    ) -> PendingExpressTxStatusRow.StatusRowData {
        let isFinished = currentStatus.isTerminated
        if isFinished {
            // Always display cross for failed state
            // TODO: Refactor for clarity
            switch status {
            case .failed:
                return .init(title: status.passedStatusTitle, state: .cross(passed: true))
            case .canceled, .unknown, .refunded:
                return .init(title: status.passedStatusTitle, state: .cross(passed: false))
            case .awaitingHash:
                return .init(title: status.passedStatusTitle, state: .exclamationMark)
            default:
                return .init(title: status.passedStatusTitle, state: .checkmark)
            }
        }

        let isCurrentStatus = index == currentStatusIndex
        let isPendingStatus = index > currentStatusIndex

        let title: String = isCurrentStatus ? status.activeStatusTitle : isPendingStatus ? status.pendingStatusTitle : status.passedStatusTitle
        var state: PendingExpressTxStatusRow.State = isCurrentStatus ? .loader : isPendingStatus ? .empty : .checkmark

        switch status {
        case .failed, .unknown, .paused:
            state = .cross(passed: false)
        case .verificationRequired, .awaitingHash:
            state = .exclamationMark
        case .refunded:
            // Refunded state is the final state and it can't be pending (with loader)
            state = isFinished ? .checkmark : .empty
        case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done, .canceled:
            break
        }

        return .init(title: title, state: state)
    }
}
