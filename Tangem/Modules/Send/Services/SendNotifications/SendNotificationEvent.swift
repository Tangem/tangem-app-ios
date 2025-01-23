//
//  SendNotificationEvent.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendNotificationEvent {
    // The send flow specific notifications
    case networkFeeUnreachable
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case accountNotActivated(assetName: String)

    // Generic notifications is received from BSDK
    case withdrawalNotificationEvent(WithdrawalNotificationEvent)
    case validationErrorEvent(ValidationErrorEvent)
}

extension SendNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .networkFeeUnreachable: "networkFeeUnreachable".hashValue
        case .feeWillBeSubtractFromSendingAmount: "feeWillBeSubtractFromSendingAmount".hashValue
        case .customFeeTooHigh: "customFeeTooHigh".hashValue
        case .customFeeTooLow: "customFeeTooLow".hashValue
        case .withdrawalNotificationEvent(let withdrawalNotificationEvent): withdrawalNotificationEvent.id
        case .validationErrorEvent(let validationErrorEvent): validationErrorEvent.id
        case .accountNotActivated: "accountNotActivated".hashValue
        }
    }

    var title: NotificationView.Title? {
        switch self {
        case .networkFeeUnreachable:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        case .feeWillBeSubtractFromSendingAmount:
            return .string(Localization.sendNetworkFeeWarningTitle)
        case .customFeeTooHigh:
            return .string(Localization.sendNotificationFeeTooHighTitle)
        case .customFeeTooLow:
            return .string(Localization.sendNotificationTransactionDelayTitle)
        case .withdrawalNotificationEvent(let event):
            return event.title
        case .validationErrorEvent(let event):
            return event.title
        case .accountNotActivated:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted):
            return Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .withdrawalNotificationEvent(let event):
            return event.description
        case .validationErrorEvent(let event):
            return event.description
        case .accountNotActivated(let assetName):
            return Localization.sendTronAccountActivationError(assetName)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable,
             .validationErrorEvent(.insufficientBalance):
            return .action
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow:
            return .secondary
        case .withdrawalNotificationEvent(let event):
            return event.colorScheme
        case .validationErrorEvent(let event):
            return event.colorScheme
        case .accountNotActivated:
            return .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkFeeUnreachable,
             .customFeeTooHigh,
             .customFeeTooLow,
             .feeWillBeSubtractFromSendingAmount:
            return .init(iconType: .image(Assets.attention.image))
        case .withdrawalNotificationEvent(let event):
            return event.icon
        case .validationErrorEvent(let event):
            return event.icon
        case .accountNotActivated:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkFeeUnreachable,
             .customFeeTooHigh,
             .customFeeTooLow,
             .feeWillBeSubtractFromSendingAmount:
            return .warning
        case .withdrawalNotificationEvent(let event):
            return event.severity
        case .validationErrorEvent(let event):
            return event.severity
        case .accountNotActivated:
            return .critical
        }
    }

    var isDismissable: Bool {
        switch self {
        case .withdrawalNotificationEvent(.reduceAmountBecauseFeeIsTooHigh):
            return true
        default:
            return false
        }
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}

extension SendNotificationEvent {
    var buttonAction: NotificationButtonAction? {
        switch self {
        case .networkFeeUnreachable:
            return .init(.refreshFee, withLoader: true)
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow,
             .accountNotActivated:
            return nil
        case .withdrawalNotificationEvent(let event):
            return event.buttonAction
        case .validationErrorEvent(let event):
            return event.buttonAction
        }
    }
}
