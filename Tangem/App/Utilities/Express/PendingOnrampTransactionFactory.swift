//
//  PendingOnrampTransactionFactory.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct PendingOnrampTransactionFactory {
    private let defaultStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .buying, .sendingToUser]
    private let failedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .failed, .refunded]
    private let verifyingStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]
    private let canceledStatusesList: [PendingExpressTransactionStatus] = [.canceled]
    private let awaitingHashStatusesList: [PendingExpressTransactionStatus] = [.awaitingHash]
    private let unknownHashStatusesList: [PendingExpressTransactionStatus] = [.unknown]
    private let pausedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .paused]

    func buildPendingOnrampTransaction(
        currentOnrampTransaction: OnrampTransaction,
        for transactionRecord: OnrampPendingTransactionRecord
    ) -> PendingOnrampTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord

        switch currentOnrampTransaction.status {
        case .created, .waitingForPayment:
            currentStatus = .awaitingDeposit
        case .paymentProcessing, .paid:
            currentStatus = .confirming
        case .sending:
            currentStatus = .sendingToUser
        case .finished:
            currentStatus = .done
        case .failed:
            currentStatus = .failed
            statusesList = failedStatusesList
        case .verifying:
            currentStatus = .verificationRequired
            statusesList = verifyingStatusesList
        case .expired:
            currentStatus = .canceled
            statusesList = canceledStatusesList
        case .paused:
            currentStatus = .paused
            statusesList = pausedStatusesList
        }

        transactionRecord.transactionStatus = currentStatus
        transactionRecord.destinationTokenTxInfo = .init(
            tokenItem: transactionRecord.destinationTokenTxInfo.tokenItem,
            amountString: currentOnrampTransaction.toAmount.map(\.stringValue) ?? "",
            isCustom: transactionRecord.destinationTokenTxInfo.isCustom
        )
        transactionRecord.externalTxURL = currentOnrampTransaction.externatTxURL

        return PendingOnrampTransaction(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }

    func buildPendingOnrampTransaction(for transactionRecord: OnrampPendingTransactionRecord) -> PendingOnrampTransaction {
        let statusesList: [PendingExpressTransactionStatus] = {
            switch transactionRecord.transactionStatus {
            case .awaitingDeposit, .confirming, .exchanging, .buying, .sendingToUser, .done:
                return defaultStatusesList
            case .canceled:
                return canceledStatusesList
            case .failed, .refunded:
                return failedStatusesList
            case .paused:
                return pausedStatusesList
            case .awaitingHash:
                return awaitingHashStatusesList
            case .unknown:
                return unknownHashStatusesList
            case .verificationRequired:
                return verifyingStatusesList
            }
        }()

        return .init(transactionRecord: transactionRecord, statuses: statusesList)
    }
}
