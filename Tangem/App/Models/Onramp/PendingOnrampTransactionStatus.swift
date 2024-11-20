//
//  PendingOnrampTransactionStatus.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum PendingOnrampTransactionStatus: String, Equatable, Codable {
    case awaitingDeposit
    case awaitingHash
    case confirming
    case exchanging
    case sendingToUser
    case done
    case failed
    case unknown
    case refunded
    case verificationRequired
    case canceled
    case paused

    var pendingStatusTitle: String {
        switch self {
        case .awaitingDeposit: Localization.expressExchangeStatusReceiving
        case .awaitingHash: Localization.expressExchangeStatusWaitingTxHash
        case .confirming: Localization.expressExchangeStatusConfirming
        case .exchanging: Localization.expressExchangeStatusExchanging
        case .sendingToUser: Localization.expressExchangeStatusSending
        case .done: Localization.commonDone
        case .failed, .unknown: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .canceled: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    var activeStatusTitle: String {
        switch self {
        case .awaitingDeposit: Localization.expressExchangeStatusReceivingActive
        case .awaitingHash: Localization.expressExchangeStatusWaitingTxHash
        case .confirming: Localization.expressExchangeStatusConfirmingActive
        case .exchanging: Localization.expressExchangeStatusExchangingActive
        case .sendingToUser: Localization.expressExchangeStatusSendingActive
        case .done: Localization.commonDone
        case .failed, .unknown: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .canceled: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    var passedStatusTitle: String {
        switch self {
        case .awaitingDeposit: Localization.expressExchangeStatusReceived
        case .awaitingHash: Localization.expressExchangeStatusWaitingTxHash
        case .confirming: Localization.expressExchangeStatusConfirmed
        case .exchanging: Localization.expressExchangeStatusExchanged
        case .sendingToUser: Localization.expressExchangeStatusSent
        case .done: Localization.commonDone
        case .failed, .unknown: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .canceled: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    var isTerminated: Bool {
        switch self {
        case .done, .refunded, .canceled:
            return true
        case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .failed, .verificationRequired, .awaitingHash, .unknown, .paused:
            return false
        }
    }

    var isDone: Bool {
        self == .done
    }
}
