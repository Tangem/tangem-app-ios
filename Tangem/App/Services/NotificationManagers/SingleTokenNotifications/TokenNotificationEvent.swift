//
//  TokenNotificationEvent.swift
//  Tangem
//
//  Created by Andrew Son on 30/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum TokenNotificationEvent: Hashable {
    case networkUnreachable(currencySymbol: String)
    case someNetworksUnreachable
    case rentFee(rentMessage: String)
    case noAccount(message: String)
    case existentialDepositWarning(message: String)
    case longTransaction(message: String)
    case hasPendingTransactions(message: String)
    case notEnoughFeeForTokenTx(tokenName: String, blockchainCurrencySymbol: String, blockchainName: String, blockchainIconName: String)
    case tangemExpressPromotion

    static func event(for reason: WalletModel.SendBlockedReason) -> TokenNotificationEvent {
        let message = reason.description
        switch reason {
        case .cantSignLongTransactions:
            return .longTransaction(message: message)
        case .hasPendingCoinTx:
            return .hasPendingTransactions(message: message)
        case .notEnoughFeeForTokenTx(let tokenName, let networkName, let coinSymbol, let chainIconName):
            return .notEnoughFeeForTokenTx(tokenName: tokenName, blockchainCurrencySymbol: coinSymbol, blockchainName: networkName, blockchainIconName: chainIconName)
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .existentialDepositWarning, .longTransaction, .hasPendingTransactions, .noAccount:
            return nil
        case .notEnoughFeeForTokenTx(_, let blockchainCurrencySymbol, _, _):
            return .openNetworkCurrency(currencySymbol: blockchainCurrencySymbol)
        case .tangemExpressPromotion:
            return .exchange
        }
    }
}

extension TokenNotificationEvent: NotificationEvent {
    var title: String {
        switch self {
        case .networkUnreachable:
            return Localization.warningNetworkUnreachableTitle
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableTitle
        case .rentFee:
            return Localization.warningRentFeeTitle
        case .noAccount:
            return Localization.warningNoAccountTitle
        case .existentialDepositWarning:
            return Localization.warningExistentialDepositTitle
        case .longTransaction:
            return Localization.warningLongTransactionTitle
        case .hasPendingTransactions:
            return Localization.warningSendBlockedPendingTransactionsTitle
        case .notEnoughFeeForTokenTx(_, _, let blockchainName, _):
            return Localization.warningSendBlockedFundsForFeeTitle(blockchainName)
        case .tangemExpressPromotion:
            return Localization.tokenSwapPromotionTitle
        }
    }

    var description: String? {
        switch self {
        case .networkUnreachable:
            return Localization.warningNetworkUnreachableMessage
        case .someNetworksUnreachable:
            return Localization.warningSomeNetworksUnreachableMessage
        case .rentFee(let message):
            return message
        case .noAccount(let message):
            return message
        case .existentialDepositWarning(let message):
            return message
        case .longTransaction(let message):
            return message
        case .hasPendingTransactions(let message):
            return message
        case .notEnoughFeeForTokenTx(let tokenName, let blockchainCurrencySymbol, let blockchainName, _):
            return Localization.warningSendBlockedFundsForFeeMessage(tokenName, blockchainName, tokenName, blockchainName, blockchainCurrencySymbol)
        case .tangemExpressPromotion:
            return Localization.tokenSwapPromotionMessage
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .noAccount:
            return .secondary
        // One white notification will be added later
        case .notEnoughFeeForTokenTx:
            return .primary
        case .tangemExpressPromotion:
            return .tangemExpressPromotion
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .longTransaction:
            return .init(iconType: .image(Assets.attention.image))
        case .rentFee, .noAccount, .existentialDepositWarning, .hasPendingTransactions:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .notEnoughFeeForTokenTx(_, _, _, let blockchainIconName):
            return .init(iconType: .image(Image(blockchainIconName)))
        case .tangemExpressPromotion:
            return .init(iconType: .image(Assets.swapBannerIcon.image), size: CGSize(bothDimensions: 34))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .noAccount,
             .rentFee,
             .existentialDepositWarning,
             .hasPendingTransactions,
             .tangemExpressPromotion:
            return .info
        case .networkUnreachable,
             .someNetworksUnreachable,
             .notEnoughFeeForTokenTx,
             .longTransaction:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee, .tangemExpressPromotion:
            return true
        case .networkUnreachable, .someNetworksUnreachable, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .notEnoughFeeForTokenTx, .noAccount:
            return false
        }
    }
}

// MARK: Analytics info

extension TokenNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .networkUnreachable: return .tokenNoticeNetworkUnreachable
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        case .rentFee: return nil
        case .noAccount: return nil
        case .existentialDepositWarning: return nil
        case .longTransaction: return nil
        case .hasPendingTransactions: return nil
        case .notEnoughFeeForTokenTx: return .tokenNoticeNotEnoughtFee
        case .tangemExpressPromotion: return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .networkUnreachable(let currencySymbol):
            return [.token: currencySymbol]
        case .notEnoughFeeForTokenTx(_, let coinSymbol, _, _):
            return [.token: coinSymbol]
        default:
            return [:]
        }
    }

    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { false }
}
