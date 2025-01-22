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

    func trackStatusForSwapTransaction(
        transactionId: String,
        tokenSymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        log(
            event: .tokenSwapStatus,
            params: [.token: tokenSymbol],
            transactionId: transactionId,
            status: status,
            provider: provider
        )
    }

    func trackStatusForOnrampTransaction(
        transactionId: String,
        tokenSymbol: String,
        currencySymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        log(
            event: .onrampOnrampStatus,
            params: [.token: tokenSymbol, .currency: currencySymbol],
            transactionId: transactionId,
            status: status,
            provider: provider
        )
    }

    private func log(
        event: Analytics.Event,
        params: [Analytics.ParameterKey: String],
        transactionId: PendingTransactionId,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        let statusToTrack = mapper.mapToAnalyticsStatus(pendingTxStatus: status)
        var trackedStatusesSet = trackedStatuses[transactionId] ?? []
        if trackedStatusesSet.contains(statusToTrack) {
            return
        }

        var params = params
        params[.status] = statusToTrack.rawValue
        params[.provider] = provider.name

        trackedStatusesSet.insert(statusToTrack)

        Analytics.log(event: event, params: params)
    }
}

extension CommonPendingExpressTransactionAnalyticsTracker {
    struct PendingExpressTransactionAnalyticsStatusMapper {
        func mapToAnalyticsStatus(pendingTxStatus: PendingExpressTransactionStatus) -> Analytics.ParameterValue {
            switch pendingTxStatus {
            case .created, .awaitingDeposit, .confirming, .buying, .exchanging, .sendingToUser:
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
