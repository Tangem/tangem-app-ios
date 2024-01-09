//
//  PendingExpressTransactionFactory.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct PendingExpressTransactionFactory {
    private let defaultStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .exchanging, .sendingToUser]
    private let failedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .failed, .refunded]
    private let verifyingStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]
    private let canceledStatusesList: [PendingExpressTransactionStatus] = [.canceled]

    func buildPendingExpressTransaction(currentExpressStatus: ExpressTransactionStatus, for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord
        switch currentExpressStatus {
        case .new, .waiting:
            currentStatus = .awaitingDeposit
        case .confirming:
            currentStatus = .confirming
        case .exchanging:
            currentStatus = .exchanging
        case .sending:
            currentStatus = .sendingToUser
        case .finished:
            currentStatus = .done
        case .failed:
            currentStatus = .failed
            statusesList = failedStatusesList
        case .refunded:
            currentStatus = .refunded
            statusesList = failedStatusesList
        case .verifying:
            currentStatus = .verificationRequired
            statusesList = verifyingStatusesList
        case .expired:
            currentStatus = .canceled
            statusesList = canceledStatusesList
        }

        transactionRecord.transactionStatus = currentStatus
        return .init(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }

    func buildPendingExpressTransaction(for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        let statusesList: [PendingExpressTransactionStatus] = {
            switch transactionRecord.transactionStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done:
                return defaultStatusesList
            case .canceled:
                return canceledStatusesList
            case .failed, .refunded:
                return failedStatusesList
            case .verificationRequired:
                return verifyingStatusesList
            }
        }()

        return .init(transactionRecord: transactionRecord, statuses: statusesList)
    }
}
