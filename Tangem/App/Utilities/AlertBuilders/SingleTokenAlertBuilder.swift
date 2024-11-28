//
//  SingleTokenAlertBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 15/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import enum BlockchainSdk.AssetRequirementsCondition

struct SingleTokenAlertBuilder {
    var cantSignLongTransactionAlert: AlertBinder {
        .init(title: Localization.warningLongTransactionTitle, message: Localization.warningLongTransactionMessage)
    }

    var tryAgainLaterAlert: AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityGenericDescription)
    }

    func receiveAlert(for requirementsCondition: AssetRequirementsCondition?) -> AlertBinder? {
        switch requirementsCondition {
        case .paidTransactionWithFee(blockchain: .hedera, _, _):
            return AlertBinder(title: "", message: Localization.warningReceiveBlockedHederaTokenAssociationRequiredMessage)
        case .paidTransactionWithFee,
             .none:
            break
        }

        return nil
    }

    func sendAlert(for sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions?) -> AlertBinder? {
        switch sendingRestrictions {
        case .hasPendingTransaction(let blockchain):
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonPendingTransactionSend(blockchain.displayName))
        case .cantSignLongTransactions:
            return cantSignLongTransactionAlert
        case .zeroWalletBalance:
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonEmptyBalanceSend)
        case .blockchainUnreachable:
            return tryAgainLaterAlert
        case .oldCard:
            return .init(title: "", message: Localization.warningOldCardMessage)
        case .none, .zeroFeeCurrencyBalance:
            break
        }

        return nil
    }

    func buyAlert(for tokenItem: TokenItem, tokenItemSwapState: TokenItemExpressState) -> AlertBinder? {
        switch tokenItemSwapState {
        case .unavailable:
            return buyUnavailableAlert(for: tokenItem)
        case .loading, .failedToLoadInfo, .notLoaded:
            return tryAgainLaterAlert
        case .available:
            return nil
        }
    }

    func swapAlert(for tokenItem: TokenItem, tokenItemSwapState: TokenItemExpressState, isCustom: Bool) -> AlertBinder? {
        let notSupportedToken = AlertBinder(
            title: "",
            message: Localization.tokenButtonUnavailabilityReasonNotExchangeable(tokenItem.name)
        )
        var alert: AlertBinder?
        switch tokenItemSwapState {
        case .unavailable:
            alert = notSupportedToken
        case .loading, .failedToLoadInfo, .notLoaded:
            alert = tryAgainLaterAlert
        case .available:
            if isCustom {
                alert = notSupportedToken
            }
        }

        return alert
    }

    func sellAlert(
        for tokenItem: TokenItem,
        sellAvailable: Bool,
        sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions?
    ) -> AlertBinder? {
        guard sellAvailable else {
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonSellUnavailable(tokenItem.name))
        }

        switch sendingRestrictions {
        case .zeroWalletBalance:
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonEmptyBalanceSell)
        case .hasPendingTransaction(let blockchain):
            return .init(title: "", message: Localization.tokenButtonUnavailabilityReasonPendingTransactionSell(blockchain.displayName))
        default:
            // All other alerts should be the same as for send
            return sendAlert(for: sendingRestrictions)
        }
    }

    func buyUnavailableAlert(for tokenItem: TokenItem) -> AlertBinder {
        .init(title: "", message: Localization.tokenButtonUnavailabilityReasonBuyUnavailable(tokenItem.name))
    }

    func fulfillAssetRequirementsAlert(
        for requirementsCondition: AssetRequirementsCondition?,
        feeTokenItem: TokenItem,
        hasFeeCurrency: Bool
    ) -> AlertBinder? {
        switch requirementsCondition {
        case .paidTransactionWithFee(blockchain: .hedera, _, feeAmount: .none) where !hasFeeCurrency:
            return AlertBinder(
                title: "",
                message: Localization.warningHederaTokenAssociationNotEnoughHbarMessage(feeTokenItem.currencySymbol)
            )
        case .paidTransactionWithFee(blockchain: .hedera, _, .some(let feeAmount)) where !hasFeeCurrency:
            assert(
                feeAmount.type == feeTokenItem.amountType,
                "Incorrect fee token item received: expected '\(feeAmount.currencySymbol)', got '\(feeTokenItem.currencySymbol)'"
            )
            return AlertBinder(
                title: "",
                message: Localization.warningHederaTokenAssociationNotEnoughHbarMessage(feeTokenItem.currencySymbol)
            )
        case .paidTransactionWithFee,
             .none:
            break
        }

        return nil
    }

    func fulfillmentAssetRequirementsFailedAlert(error: Error, networkName: String) -> AlertBinder {
        return .init(
            title: Localization.commonTransactionFailed,
            message: networkName + " " + error.localizedDescription
        )
    }

    func fulfillAssetRequirementsDiscardedAlert(confirmationAction: @escaping () -> Void) -> AlertBinder {
        return AlertBinder(
            alert: Alert(
                title: Text(Localization.commonWarning),
                message: Text(Localization.warningKaspaUnfinishedTokenTransactionDiscardMessage),
                primaryButton: .default(Text(Localization.commonNo)),
                secondaryButton: .destructive(Text(Localization.commonYes), action: confirmationAction)
            )
        )
    }
}
