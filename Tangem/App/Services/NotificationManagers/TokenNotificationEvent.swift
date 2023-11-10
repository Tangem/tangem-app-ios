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
    case networkUnreachable
    case someNetworksUnreachable
    case rentFee(rentMessage: String)
    case noAccount(message: String)
    case existentialDepositWarning(message: String)
    case longTransaction(message: String)
    case hasPendingTransactions(message: String)
    case notEnoughtFeeForTokenTx(tokenName: String, blockchainCurrencySymbol: String, blockchainName: String, blockchainIconName: String)

    static func event(for reason: WalletModel.SendBlockedReason) -> TokenNotificationEvent {
        let message = reason.description
        switch reason {
        case .cantSignLongTransactions:
            return .longTransaction(message: message)
        case .hasPendingCoinTx:
            return .hasPendingTransactions(message: message)
        case .notEnoughtFeeForTokenTx(let tokenName, let networkName, let coinSymbol, let chainIconName):
            return .notEnoughtFeeForTokenTx(tokenName: tokenName, blockchainCurrencySymbol: coinSymbol, blockchainName: networkName, blockchainIconName: chainIconName)
        }
    }

    var buttonAction: NotificationButtonActionType? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .existentialDepositWarning, .longTransaction, .hasPendingTransactions, .noAccount:
            return nil
        case .notEnoughtFeeForTokenTx(_, let blockchainCurrencySymbol, _, _):
            return .openNetworkCurrency(currencySymbol: blockchainCurrencySymbol)
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
        case .notEnoughtFeeForTokenTx(_, _, let blockchainName, _):
            return Localization.warningSendBlockedFundsForFeeTitle(blockchainName)
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
        case .notEnoughtFeeForTokenTx(let tokenName, let blockchainCurrencySymbol, let blockchainName, _):
            return Localization.warningSendBlockedFundsForFeeMessage(tokenName, blockchainName, tokenName, blockchainName, blockchainCurrencySymbol)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .rentFee, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .noAccount:
            return .secondary
        // One white notification will be added later
        case .notEnoughtFeeForTokenTx:
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .someNetworksUnreachable, .longTransaction:
            return .init(image: Assets.attention.image)
        case .rentFee, .noAccount, .existentialDepositWarning, .hasPendingTransactions:
            return .init(image: Assets.blueCircleWarning.image)
        case .notEnoughtFeeForTokenTx(_, _, _, let blockchainIconName):
            return .init(image: Image(blockchainIconName))
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee:
            return true
        case .networkUnreachable, .someNetworksUnreachable, .longTransaction, .existentialDepositWarning, .hasPendingTransactions, .notEnoughtFeeForTokenTx, .noAccount:
            return false
        }
    }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .networkUnreachable: return .tokenNoticeNetworkUnreachable
        case .someNetworksUnreachable: return .mainNoticeNetworksUnreachable
        case .rentFee: return nil
        case .noAccount: return nil
        case .existentialDepositWarning: return nil
        case .longTransaction: return nil
        case .hasPendingTransactions: return nil
        case .notEnoughtFeeForTokenTx: return .tokenNoticeNotEnoughtFee
        }
    }
}
