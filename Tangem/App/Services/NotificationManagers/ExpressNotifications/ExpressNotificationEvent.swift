//
//  ExpressNotificationEvent.swift
//  Tangem
//
//  Created by Andrew Son on 21/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemExpress

enum ExpressNotificationEvent: Hashable {
    // Express specific notifications
    case permissionNeeded(providerName: String, currencyCode: String)
    case refreshRequired(
        title: String,
        message: String,
        expressErrorCode: ExpressAPIError.Code? = nil,
        analyticsParams: [Analytics.ParameterKey: String]? = nil
    )
    case hasPendingTransaction(symbol: String)
    case hasPendingApproveTransaction
    case notEnoughFeeForTokenTx(mainTokenName: String, mainTokenSymbol: String, blockchainIconName: String)
    case tooSmallAmountToSwap(minimumAmountText: String)
    case tooBigAmountToSwap(maximumAmountText: String)
    case noDestinationTokens(sourceTokenName: String)
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
    case notEnoughReceivedAmountForReserve(amountFormatted: String)

    // Generic notifications is received from BSDK
    case withdrawalNotificationEvent(WithdrawalNotificationEvent)
    case validationErrorEvent(event: ValidationErrorEvent, context: ValidationErrorContext)

    // The notifications which is used only on the PendingExpressTxStatusBottomSheetView
    case verificationRequired
    case cexOperationFailed

    case refunded(tokenItem: TokenItem)
}

extension ExpressNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .permissionNeeded:
            return .string(Localization.expressProviderPermissionNeeded)
        case .refreshRequired(let title, _, _, _):
            return .string(title)
        case .hasPendingTransaction:
            return .string(Localization.warningExpressActiveTransactionTitle)
        case .hasPendingApproveTransaction:
            return .string(Localization.warningExpressApprovalInProgressTitle)
        case .notEnoughFeeForTokenTx(let mainTokenName, _, _):
            return .string(Localization.warningExpressNotEnoughFeeForTokenTxTitle(mainTokenName))
        case .tooSmallAmountToSwap(let minimumAmountText):
            return .string(Localization.warningExpressTooMinimalAmountTitle(minimumAmountText))
        case .tooBigAmountToSwap(let maximumAmountText):
            return .string(Localization.warningExpressTooMaximumAmountTitle(maximumAmountText))
        case .noDestinationTokens:
            return .string(Localization.warningExpressNoExchangeableCoinsTitle)
        case .verificationRequired:
            return .string(Localization.expressExchangeNotificationVerificationTitle)
        case .cexOperationFailed:
            return .string(Localization.expressExchangeNotificationFailedTitle)
        case .feeWillBeSubtractFromSendingAmount:
            return .string(Localization.sendNetworkFeeWarningTitle)
        case .notEnoughReceivedAmountForReserve(let amountFormatted):
            return .string(Localization.warningExpressNotificationInvalidReserveAmountTitle(amountFormatted))
        case .withdrawalNotificationEvent(let event):
            return event.title
        case .validationErrorEvent(let event, _):
            return event.title
        case .refunded(tokenItem: let tokenItem):
            return .string(Localization.expressExchangeNotificationRefundTitle(tokenItem.currencySymbol, tokenItem.networkName))
        }
    }

    var description: String? {
        switch self {
        case .permissionNeeded(let providerName, let currencyCode):
            return Localization.givePermissionSwapSubtitle(providerName, currencyCode)
        case .refreshRequired(_, let message, _, _):
            return message
        case .hasPendingTransaction(let symbol):
            return Localization.warningExpressActiveTransactionMessage(symbol)
        case .hasPendingApproveTransaction:
            return Localization.warningExpressApprovalInProgressMessage
        case .notEnoughFeeForTokenTx(let mainTokenName, let mainTokenSymbol, _):
            return Localization.warningExpressNotEnoughFeeForTokenTxDescription(mainTokenName, mainTokenSymbol)
        case .tooSmallAmountToSwap, .tooBigAmountToSwap:
            return Localization.warningExpressWrongAmountDescription
        case .notEnoughReceivedAmountForReserve:
            return Localization.sendNotificationInvalidReserveAmountText
        case .noDestinationTokens(let sourceTokenName):
            return Localization.warningExpressNoExchangeableCoinsDescription(sourceTokenName)
        case .verificationRequired:
            return Localization.expressExchangeNotificationVerificationText
        case .cexOperationFailed:
            return Localization.expressExchangeNotificationFailedText
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted):
            return Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        // Only for dustRestriction we have to use different description
        case .validationErrorEvent(.dustRestriction(let minimumAmountFormatted, let minimumChangeFormatted), _):
            return Localization.warningExpressDustMessage(minimumAmountFormatted, minimumChangeFormatted)
        case .withdrawalNotificationEvent(let event):
            return event.description
        case .validationErrorEvent(let event, _):
            return event.description
        case .refunded(tokenItem: let tokenItem):
            let url = TangemBlogUrlBuilder().url(post: .refundedDex)
            let readMore = "[\(Localization.commonReadMore)](\(url.absoluteString))"
            return Localization.expressExchangeNotificationRefundText(tokenItem.currencySymbol, readMore)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .permissionNeeded,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .noDestinationTokens,
             .feeWillBeSubtractFromSendingAmount:
            return .secondary
        case .notEnoughFeeForTokenTx,
             .refreshRequired,
             .verificationRequired,
             .cexOperationFailed,
             .notEnoughReceivedAmountForReserve,
             .refunded:
            return .action
        case .withdrawalNotificationEvent(let event):
            return event.colorScheme
        case .validationErrorEvent(let event, _):
            return event.colorScheme
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .permissionNeeded:
            return .init(iconType: .image(Assets.swapLock.image))
        case .refreshRequired,
             .noDestinationTokens,
             .verificationRequired,
             .feeWillBeSubtractFromSendingAmount:
            return .init(iconType: .image(Assets.attention.image))
        case .hasPendingApproveTransaction,
             .hasPendingTransaction:
            return .init(iconType: .progressView)
        case .notEnoughFeeForTokenTx(_, _, let blockchainIconName):
            return .init(iconType: .image(Image(blockchainIconName)))
        case .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .cexOperationFailed,
             .notEnoughReceivedAmountForReserve:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .withdrawalNotificationEvent(let event):
            return event.icon
        case .validationErrorEvent(let event, _):
            return event.icon
        case .refunded(let tokenItem):
            let iconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)
            return .init(iconType: .icon(iconInfo), size: CGSize(bothDimensions: 36))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .permissionNeeded,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .verificationRequired,
             .feeWillBeSubtractFromSendingAmount,
             .refunded:
            return .info
        case .notEnoughFeeForTokenTx,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .noDestinationTokens,
             .notEnoughReceivedAmountForReserve:
            return .warning
        case .refreshRequired,
             .cexOperationFailed:
            return .critical
        case .withdrawalNotificationEvent(let event):
            return event.severity
        case .validationErrorEvent(let event, _):
            return event.severity
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .notEnoughFeeForTokenTx(_, let mainTokenSymbol, _):
            return .init(.openFeeCurrency(currencySymbol: mainTokenSymbol))
        case .refreshRequired:
            return .init(.refresh, withLoader: true)
        case .verificationRequired, .cexOperationFailed:
            return .init(.goToProvider)
        case .validationErrorEvent(let event, _):
            return event.buttonAction
        case .withdrawalNotificationEvent(let event):
            return event.buttonAction
        case .refunded:
            return .init(.openCurrency)
        default:
            return nil
        }
    }

    var removingOnFullLoadingState: Bool {
        switch self {
        case .noDestinationTokens, .refreshRequired, .verificationRequired, .cexOperationFailed, .refunded:
            return false
        case .permissionNeeded,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .notEnoughFeeForTokenTx,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .feeWillBeSubtractFromSendingAmount,
             .notEnoughReceivedAmountForReserve,
             .withdrawalNotificationEvent,
             .validationErrorEvent:
            return true
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Analytics

// TODO: Add analytics
extension ExpressNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .refreshRequired(_, _, .exchangeNotPossibleError, _):
            .swapNoticeExpressError
        default:
            nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .refreshRequired(_, _, _, .some(let params)):
            params
        default:
            [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        return false
    }
}
