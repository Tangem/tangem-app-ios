//
//  PendingExpressTransactionStatus.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum PendingExpressTransactionStatus: String, Equatable, Codable {
    case awaitingDeposit
    case awaitingHash
    case confirming
    case buying
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
        case .buying: "Buying"
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
        case .buying: "Buying..."
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
        case .buying: "Bought"
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
        case .awaitingDeposit, .confirming, .exchanging, .buying, .sendingToUser, .failed, .verificationRequired, .awaitingHash, .unknown, .paused:
            return false
        }
    }

    var isDone: Bool {
        self == .done
    }
}
