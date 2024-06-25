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

    // Generic notifications is received from BSDK
    case withdrawalNotificationEvent(WithdrawalNotificationEvent)
    case validationErrorEvent(ValidationErrorEvent)
}

extension SendNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
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
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable,
             .validationErrorEvent(.insufficientBalance): // Check it. It hasn't button:
            // ♿️ Does it have a button? Use `action`
            return .action
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow:
            return .secondary
        case .withdrawalNotificationEvent(let event):
            return event.colorScheme
        case .validationErrorEvent(let event):
            return event.colorScheme
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkFeeUnreachable,
             .customFeeTooHigh,
             .customFeeTooLow,
             .feeWillBeSubtractFromSendingAmount:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.attention.image))
        case .withdrawalNotificationEvent(let event):
            return event.icon
        case .validationErrorEvent(let event):
            return event.icon
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkFeeUnreachable,
             .customFeeTooHigh,
             .customFeeTooLow,
             .feeWillBeSubtractFromSendingAmount:
            // ⚠️ sync with SendNotificationEvent.icon
            return .warning
        case .withdrawalNotificationEvent(let event):
            return event.severity
        case .validationErrorEvent(let event):
            return event.severity
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
    enum Location {
        case feeLevels
        case customFee
        case feeIncluded
        case summary
    }

    var locations: [Location] {
        switch self {
        case .networkFeeUnreachable:
            return [.feeLevels, .summary]
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow,
             .withdrawalNotificationEvent,
             .validationErrorEvent:
            return [.summary]
        }
    }
}

extension SendNotificationEvent {
    // ♿️ Does it have a button? Use `action` color scheme then ☝️
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .networkFeeUnreachable:
            return .refreshFee
        case .feeWillBeSubtractFromSendingAmount,
             .customFeeTooHigh,
             .customFeeTooLow:
            return nil
        case .withdrawalNotificationEvent(let event):
            return event.buttonActionType
        case .validationErrorEvent(let event):
            return event.buttonActionType
        }
    }
}

extension SendNotificationEvent {
    var id: String {
        switch self {
        case .networkFeeUnreachable:
            "networkFeeUnreachable"
        case .feeWillBeSubtractFromSendingAmount:
            "feeWillBeSubtractFromSendingAmount"
        case .customFeeTooHigh:
            "customFeeTooHigh"
        case .customFeeTooLow:
            "customFeeTooLow"
        case .withdrawalNotificationEvent(let event):
            event.id
        case .validationErrorEvent(let event):
            event.id
        }
    }
}
