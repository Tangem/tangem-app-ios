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
    static func makeDismissAlert(dismissAction: @escaping () -> Void) -> AlertBinder {
        let dismissButton = Alert.Button.default(Text(Localization.commonYes), action: dismissAction)
        let cancelButton = Alert.Button.cancel(Text(Localization.commonNo))
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendDismissMessage,
            primaryButton: dismissButton,
            secondaryButton: cancelButton
        )
    }

    static func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder {
        let retryButton = Alert.Button.default(Text(Localization.commonRetry), action: retryAction)
        return AlertBuilder.makeAlert(
            title: Localization.sendFeeUnreachableErrorTitle,
            message: Localization.sendFeeUnreachableErrorText,
            primaryButton: retryButton,
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

    static func makeCustomFeeTooHighAlert(_ orderOfMagnitude: Int, continueAction: @escaping () -> Void) -> AlertBinder {
        let continueButton = Alert.Button.default(Text(Localization.commonContinue), action: continueAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeTooHighText(orderOfMagnitude),
            primaryButton: continueButton,
            secondaryButton: .cancel()
        )
    }
}
