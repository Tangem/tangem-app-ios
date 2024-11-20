//
//  PendingOnrampTransactionFactory.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct PendingOnrampTransactionFactory {
    private let defaultStatusesList: [PendingOnrampTransactionStatus] = [.awaitingDeposit, .confirming, .exchanging, .sendingToUser]
    private let failedStatusesList: [PendingOnrampTransactionStatus] = [.awaitingDeposit, .confirming, .failed, .refunded]
    private let verifyingStatusesList: [PendingOnrampTransactionStatus] = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]
    private let canceledStatusesList: [PendingOnrampTransactionStatus] = [.canceled]
    private let awaitingHashStatusesList: [PendingOnrampTransactionStatus] = [.awaitingHash]
    private let unknownHashStatusesList: [PendingOnrampTransactionStatus] = [.unknown]
    private let pausedStatusesList: [PendingOnrampTransactionStatus] = [.awaitingDeposit, .confirming, .paused]

    func buildPendingOnrampTransaction(
        currentOnrampStatus: OnrampTransactionStatus,
        for transactionRecord: OnrampPendingTransactionRecord
    ) -> PendingOnrampTransaction {
        let currentStatus: PendingOnrampTransactionStatus
        var statusesList: [PendingOnrampTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord

        switch currentOnrampStatus {
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

        return PendingOnrampTransaction(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }

    func buildPendingOnrampTransaction(for transactionRecord: OnrampPendingTransactionRecord) -> PendingOnrampTransaction {
        let statusesList: [PendingOnrampTransactionStatus] = {
            switch transactionRecord.transactionStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done:
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
