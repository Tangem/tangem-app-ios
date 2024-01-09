//
//  CommonPendingExpressTransactionAnalyticsTracker.swift
//  Tangem
//
//  Created by Andrew Son on 06/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonPendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker {
    typealias PendingTransactionId = String

    private let mapper = PendingExpressTransactionAnalyticsStatusMapper()
    private var trackedStatuses = [PendingTransactionId: Set<Analytics.ParameterValue>]()

    func trackStatusForTransaction(with transactionId: PendingTransactionId, tokenSymbol: String, status: PendingExpressTransactionStatus) {
        let statusToTrack = mapper.mapToAnalyticsStatus(pendingTxStatus: status)
        var trackedStatusesSet = trackedStatuses[transactionId] ?? []
        if trackedStatusesSet.contains(statusToTrack) {
            return
        }

        Analytics.log(event: .tokenChangeNowStatus, params: [
            .token: tokenSymbol,
            .status: statusToTrack.rawValue,
        ])
        trackedStatusesSet.insert(statusToTrack)
        trackedStatuses[transactionId] = trackedStatusesSet
    }
}

extension CommonPendingExpressTransactionAnalyticsTracker {
    struct PendingExpressTransactionAnalyticsStatusMapper {
        func mapToAnalyticsStatus(pendingTxStatus: PendingExpressTransactionStatus) -> Analytics.ParameterValue {
            switch pendingTxStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser:
                return .inProgress
            case .done:
                return .done
            case .failed:
                return .fail
            case .refunded:
                return .refunded
            case .verificationRequired:
                return .kyc
            case .canceled:
                return .canceled
            }
        }
    }
}
