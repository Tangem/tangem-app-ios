//
//  CommonPendingExpressTransactionAnalyticsTracker.swift
//  Tangem
//
//  Created by Andrew Son on 06/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemExpress

class CommonPendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker {
    typealias PendingTransactionId = String

    private let mapper = PendingExpressTransactionAnalyticsStatusMapper()
    private var trackedStatuses: ThreadSafeContainer<[PendingTransactionId: Set<Analytics.ParameterValue>]> = .init([:])

    func trackStatusForTransaction(
        branch: ExpressBranch,
        transactionId: PendingTransactionId,
        tokenSymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        let statusToTrack = mapper.mapToAnalyticsStatus(pendingTxStatus: status)
        var trackedStatusesSet = trackedStatuses[transactionId] ?? []
        if trackedStatusesSet.contains(statusToTrack) {
            return
        }

        let params: [Analytics.ParameterKey: String] = [
            .token: tokenSymbol,
            .status: statusToTrack.rawValue,
            .provider: provider.name,
        ]

        switch branch {
        case .swap:
            Analytics.log(event: .tokenSwapStatus, params: params)
        case .onramp:
            Analytics.log(event: .onrampOnrampStatus, params: params)
        }

        trackedStatusesSet.insert(statusToTrack)
        trackedStatuses.mutate { $0[transactionId] = trackedStatusesSet }
    }
}

extension CommonPendingExpressTransactionAnalyticsTracker {
    struct PendingExpressTransactionAnalyticsStatusMapper {
        func mapToAnalyticsStatus(pendingTxStatus: PendingExpressTransactionStatus) -> Analytics.ParameterValue {
            switch pendingTxStatus {
            case .awaitingDeposit, .confirming, .buying, .exchanging, .sendingToUser:
                return .inProgress
            case .done:
                return .done
            case .failed, .awaitingHash, .unknown, .paused:
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
