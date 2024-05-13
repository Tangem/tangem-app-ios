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
    case networkFeeUnreachable
    // When fee currency is same as fee currency
    case totalExceedsBalance
    // When fee currency is different
    case feeExceedsBalance(configuration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration)
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
    case existentialDeposit(amount: Decimal, amountFormatted: String)
    case customFeeTooHigh(orderOfMagnitude: Int)
    case customFeeTooLow
    case minimumAmount(value: String)
    case withdrawalOptionalAmountChange(amount: Decimal, amountFormatted: String, blockchainName: String)
    case withdrawalMandatoryAmountChange(amount: Decimal, amountFormatted: String, blockchainName: String, maxUtxo: Int)
}

extension SendNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .networkFeeUnreachable:
            return .string(Localization.sendFeeUnreachableErrorTitle)
        case .totalExceedsBalance:
            return .string(Localization.sendNotificationExceedBalanceTitle)
        case .feeExceedsBalance(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.feeAmountTypeName))
        case .feeWillBeSubtractFromSendingAmount:
            return .string(Localization.sendNetworkFeeWarningTitle)
        case .existentialDeposit:
            return .string(Localization.sendNotificationExistentialDepositTitle)
        case .customFeeTooHigh:
            return .string(Localization.sendNotificationFeeTooHighTitle)
        case .customFeeTooLow:
            return .string(Localization.sendNotificationTransactionDelayTitle)
        case .minimumAmount:
            return .string(Localization.sendNotificationInvalidAmountTitle)
        case .withdrawalOptionalAmountChange:
            return .string(Localization.sendNotificationHighFeeTitle)
        case .withdrawalMandatoryAmountChange:
            return .string(Localization.sendNotificationTransactionLimitTitle)
        }
    }

    var description: String? {
        switch self {
        case .networkFeeUnreachable:
            return Localization.sendFeeUnreachableErrorText
        case .totalExceedsBalance:
            return Localization.sendNotificationExceedBalanceText
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted):
            return Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        case .feeExceedsBalance(let configuration):
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.transactionAmountTypeName,
                configuration.networkName,
                configuration.transactionAmountTypeName,
                configuration.feeAmountTypeName,
                configuration.feeAmountTypeCurrencySymbol
            )
        case .existentialDeposit(_, let amountFormatted):
            return Localization.sendNotificationExistentialDepositText(amountFormatted)
        case .customFeeTooHigh(let orderOfMagnitude):
            return Localization.sendNotificationFeeTooHighText(orderOfMagnitude)
        case .customFeeTooLow:
            return Localization.sendNotificationTransactionDelayText
        case .minimumAmount(let value):
            return Localization.sendNotificationInvalidMinimumAmountText(value, value)
        case .withdrawalOptionalAmountChange(_, let amount, let blockchainName):
            return Localization.sendNotificationHighFeeText(blockchainName, amount)
        case .withdrawalMandatoryAmountChange(_, let amountFormatted, let blockchainName, let maxUtxo):
            return Localization.sendNotificationTransactionLimitText(blockchainName, maxUtxo, amountFormatted)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkFeeUnreachable, .totalExceedsBalance, .feeExceedsBalance, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange, .existentialDeposit:
            // ♿️ Does it have a button? Use `action`
            return .action
        case .feeWillBeSubtractFromSendingAmount, .customFeeTooHigh, .customFeeTooLow, .minimumAmount:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .totalExceedsBalance, .minimumAmount, .withdrawalMandatoryAmountChange, .existentialDeposit:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .feeWillBeSubtractFromSendingAmount, .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .withdrawalOptionalAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Assets.attention.image))
        case .feeExceedsBalance(let configuration):
            // ⚠️ sync with SendNotificationEvent.icon
            return .init(iconType: .image(Image(configuration.feeAmountTypeIconName)))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .totalExceedsBalance, .minimumAmount, .withdrawalMandatoryAmountChange, .existentialDeposit:
            // ⚠️ sync with SendNotificationEvent.icon
            return .critical
        case .feeWillBeSubtractFromSendingAmount, .networkFeeUnreachable, .customFeeTooHigh, .customFeeTooLow, .withdrawalOptionalAmountChange:
            // ⚠️ sync with SendNotificationEvent.icon
            return .warning
        case .feeExceedsBalance:
            // ⚠️ sync with SendNotificationEvent.icon
            return .critical
        }
    }

    var isDismissable: Bool {
        switch self {
        case .withdrawalOptionalAmountChange:
            true
        default:
            false
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

    var location: Location {
        switch self {
        case .networkFeeUnreachable:
            return .feeLevels
        case .feeWillBeSubtractFromSendingAmount, .minimumAmount, .existentialDeposit, .withdrawalOptionalAmountChange, .withdrawalMandatoryAmountChange, .totalExceedsBalance, .customFeeTooHigh, .customFeeTooLow, .feeExceedsBalance:
            return .summary
        }
    }
}

extension SendNotificationEvent {
    // ♿️ Does it have a button? Use `action` color scheme then ☝️
    var buttonActionType: NotificationButtonActionType? {
        switch self {
        case .networkFeeUnreachable:
            return .refreshFee
        case .feeExceedsBalance(let configuration):
            return .openFeeCurrency(currencySymbol: configuration.feeAmountTypeCurrencySymbol)
        case .withdrawalOptionalAmountChange(let amount, let amountFormatted, _), .existentialDeposit(let amount, let amountFormatted):
            return .reduceAmountBy(amount: amount, amountFormatted: amountFormatted)
        case .withdrawalMandatoryAmountChange(let amount, let amountFormatted, _, _):
            return .reduceAmountTo(amount: amount, amountFormatted: amountFormatted)
        case .feeWillBeSubtractFromSendingAmount, .totalExceedsBalance, .customFeeTooHigh, .customFeeTooLow, .minimumAmount:
            return nil
        }
    }
}

extension SendNotificationEvent {
    var id: String {
        switch self {
        case .networkFeeUnreachable:
            "networkFeeUnreachable"
        case .totalExceedsBalance:
            "totalExceedsBalance"
        case .feeWillBeSubtractFromSendingAmount:
            "feeWillBeSubtractFromSendingAmount"
        case .feeExceedsBalance:
            "feeExceedsBalance"
        case .existentialDeposit:
            "existentialDeposit"
        case .customFeeTooHigh:
            "customFeeTooHigh"
        case .customFeeTooLow:
            "customFeeTooLow"
        case .minimumAmount:
            "minimumAmount"
        case .withdrawalOptionalAmountChange:
            "withdrawalOptionalAmountChange"
        case .withdrawalMandatoryAmountChange:
            "withdrawalMandatoryAmountChange"
        }
    }
}
