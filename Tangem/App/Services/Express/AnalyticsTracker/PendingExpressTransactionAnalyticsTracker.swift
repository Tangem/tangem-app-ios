//
//  PendingExpressTransactionAnalyticsTracker.swift
//  Tangem
//
//  Created by Andrew Son on 06/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol PendingExpressTransactionAnalyticsTracker {
    func trackStatusForTransaction(
        with transactionId: String,
        tokenSymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    )
}

private struct PendingExpressTransactionAnalyticsTrackerKey: InjectionKey {
    static var currentValue: PendingExpressTransactionAnalyticsTracker = CommonPendingExpressTransactionAnalyticsTracker()
}

extension InjectedValues {
    var pendingExpressTransactionAnalayticsTracker: PendingExpressTransactionAnalyticsTracker {
        get { Self[PendingExpressTransactionAnalyticsTrackerKey.self] }
        set { Self[PendingExpressTransactionAnalyticsTrackerKey.self] = newValue }
    }
}
