//
//  SendAlertBuilder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk

protocol SendAlertBuilder {
    func makeTransactionFailedAlert(sendTxError: SendTxError, openMailAction: @escaping () -> Void) -> AlertBinder
    func makeDismissAlert(dismissAction: @escaping () -> Void) -> AlertBinder
    func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder
}

// MARK: Default

extension SendAlertBuilder {
    func makeTransactionFailedAlert(sendTxError: SendTxError, openMailAction: @escaping () -> Void) -> AlertBinder {
        let reason = String(sendTxError.localizedDescription.dropTrailingPeriod)
        let errorCode = (sendTxError.error as? ErrorCodeProviding).map { "\($0.errorCode)" } ?? "-"

        return AlertBuilder.makeAlert(
            title: Localization.sendAlertTransactionFailedTitle,
            message: Localization.sendAlertTransactionFailedText(reason, errorCode),
            primaryButton: .default(Text(Localization.alertButtonRequestSupport), action: openMailAction),
            secondaryButton: .default(Text(Localization.commonCancel))
        )
    }

    func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.sendFeeUnreachableErrorTitle,
            message: Localization.sendFeeUnreachableErrorText,
            primaryButton: .default(Text(Localization.commonRetry), action: retryAction),
            secondaryButton: .cancel()
        )
    }
}
