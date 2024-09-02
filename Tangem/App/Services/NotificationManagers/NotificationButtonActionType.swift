//
//  NotificationButtonActionType.swift
//  Tangem
//
//  Created by Andrew Son on 04/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NotificationButtonAction {
    let type: NotificationButtonActionType
    let withLoader: Bool

    init(_ type: NotificationButtonActionType, withLoader: Bool = false) {
        self.type = type
        self.withLoader = withLoader
    }
}

enum NotificationButtonActionType: Identifiable, Hashable {
    case generateAddresses
    case backupCard
    case buyCrypto(currencySymbol: String?)
    case openFeeCurrency(currencySymbol: String)
    case refresh
    case refreshFee
    case goToProvider
    case leaveAmount(amount: Decimal, amountFormatted: String)
    case reduceAmountBy(amount: Decimal, amountFormatted: String)
    case reduceAmountTo(amount: Decimal, amountFormatted: String)
    case openLink(promotionLink: URL, buttonTitle: String)
    case swap
    case addHederaTokenAssociation
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
    case addTokenTrustline
    case stake
    /// Rate the app
    case openFeedbackMail
    /// Rate the app.
    case openAppStoreReview
    /// No action
    case empty
    case support
    case openCurrency

    var id: Int { hashValue }

    var title: String {
        switch self {
        case .generateAddresses:
            return Localization.commonGenerateAddresses
        case .backupCard:
            return Localization.buttonStartBackupProcess
        case .buyCrypto(let currencySymbol):
            guard let currencySymbol else {
                // TODO: Replace when texts will be confirmed
                return "Top up card"
            }
            return Localization.commonBuyCurrency(currencySymbol)
        case .openFeeCurrency(let currencySymbol):
            return Localization.commonBuyCurrency(currencySymbol)
        case .refresh, .refreshFee:
            return Localization.warningButtonRefresh
        case .goToProvider:
            return Localization.commonGoToProvider
        case .reduceAmountBy(_, let amountFormatted):
            return Localization.sendNotificationReduceBy(amountFormatted)
        case .reduceAmountTo(_, let amountFormatted), .leaveAmount(_, let amountFormatted):
            return Localization.sendNotificationLeaveButton(amountFormatted)
        case .openLink(_, let buttonTitle):
            return buttonTitle
        case .addHederaTokenAssociation:
            return Localization.warningHederaMissingTokenAssociationButtonTitle
        case .stake:
            return Localization.commonStake
        case .openFeedbackMail:
            return Localization.warningButtonCouldBeBetter
        case .openAppStoreReview:
            return Localization.warningButtonReallyCool
        case .swap:
            return Localization.tokenSwapPromotionButton
        case .empty:
            return ""
        case .support:
            return Localization.detailsRowTitleContactToSupport
        case .openCurrency:
            return Localization.commonGoToToken
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses:
            return .trailing(Assets.tangemIcon)
        case .swap:
            return .leading(Assets.exchangeMini)
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .leaveAmount,
             .addHederaTokenAssociation,
             .openLink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .empty,
             .support,
             .openCurrency:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses,
             .openLink,
             .openAppStoreReview,
             .empty:
            return .primary
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .leaveAmount,
             .support,
             .stake,
             .openFeedbackMail,
             .openCurrency,
             .swap:
            return .secondary
        }
    }
}
