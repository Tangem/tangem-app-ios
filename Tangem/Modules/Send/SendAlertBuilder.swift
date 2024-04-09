//
//  SendAlertBuilder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendAlertBuilder {
    static func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder {
        let retryButton = Alert.Button.default(Text(Localization.commonRetry), action: retryAction)
        return AlertBuilder.makeAlert(
            title: Localization.sendFeeUnreachableErrorTitle,
            message: Localization.sendFeeUnreachableErrorText,
            primaryButton: retryButton
        )
    }

    static func makeSubtractFeeFromAmountAlert(_ fee: String, subtractAction: @escaping () -> Void) -> AlertBinder {
        let subtractButton = Alert.Button.default(Text(Localization.sendAlertFeeCoverageSubractText), action: subtractAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeCoverageTitle(fee),
            primaryButton: subtractButton,
            secondaryButton: .cancel()
        )
    }

    static func makeCustomFeeTooLowAlert(continueAction: @escaping () -> Void) -> AlertBinder {
        let continueButton = Alert.Button.default(Text(Localization.commonContinue), action: continueAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeTooLowText,
            primaryButton: continueButton,
            secondaryButton: .cancel()
        )
    }
}
