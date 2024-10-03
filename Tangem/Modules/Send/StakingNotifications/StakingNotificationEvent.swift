//
//  StakingNotificationEvent.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

enum StakingNotificationEvent {
    case approveTransactionInProgress
    case unstake(description: String)
    case withdraw
    case claimRewards
    case restakeRewards
    case revote
    case unlock(periodFormatted: String)
    case validationErrorEvent(ValidationErrorEvent)
    case networkUnreachable
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
    case stakesWillMoveToNewValidator(blockchain: String)
}

extension StakingNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .approveTransactionInProgress: "approveTransactionInProgress".hashValue
        case .feeWillBeSubtractFromSendingAmount: "feeWillBeSubtractFromSendingAmount".hashValue
        case .unstake: "unstake".hashValue
        case .withdraw: "withdraw".hashValue
        case .claimRewards: "claimRewards".hashValue
        case .restakeRewards: "restakeRewards".hashValue
        case .revote: "revote".hashValue
        case .unlock: "unlock".hashValue
        case .validationErrorEvent(let validationErrorEvent): validationErrorEvent.id
        case .networkUnreachable: "networkUnreachable".hashValue
        case .stakesWillMoveToNewValidator: "stakesWillMoveToNewValidator".hashValue
        }
    }

    var title: NotificationView.Title {
        switch self {
        case .approveTransactionInProgress: .string(Localization.warningExpressApprovalInProgressTitle)
        case .feeWillBeSubtractFromSendingAmount: .string(Localization.sendNetworkFeeWarningTitle)
        case .unstake: .string(Localization.commonUnstake)
        case .withdraw: .string(Localization.stakingWithdraw)
        case .claimRewards: .string(Localization.commonClaim)
        case .restakeRewards: .string(Localization.stakingRestake)
        case .revote: .string(Localization.stakingRevote)
        case .unlock: .string(Localization.stakingUnlockedLocked)
        case .validationErrorEvent(let event): event.title
        case .networkUnreachable: .string(Localization.sendFeeUnreachableErrorTitle)
        case .stakesWillMoveToNewValidator: .string(Localization.stakingRevote)
        }
    }

    var description: String? {
        switch self {
        case .approveTransactionInProgress:
            Localization.warningExpressApprovalInProgressMessage
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, let fiatAmountFormatted):
            Localization.commonNetworkFeeWarningContent(cryptoAmountFormatted, fiatAmountFormatted)
        case .unstake(let description):
            description
        case .withdraw:
            Localization.stakingNotificationWithdrawText
        case .claimRewards:
            Localization.stakingNotificationClaimRewardsText
        case .restakeRewards:
            Localization.stakingNotificationRestakeRewardsText
        case .revote:
            // revote is implemented only for Tron
            Localization.stakingNotificationsRevoteTronText
        case .unlock(let period):
            Localization.stakingNotificationUnlockText(period)
        case .validationErrorEvent(let event):
            event.description
        case .networkUnreachable:
            Localization.sendFeeUnreachableErrorText
        case .stakesWillMoveToNewValidator(let blockchain):
            Localization.stakingNotificationNewValidatorFundsTransfer(blockchain)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .approveTransactionInProgress, .feeWillBeSubtractFromSendingAmount, .stakesWillMoveToNewValidator: .secondary
        case .unstake, .networkUnreachable, .withdraw, .claimRewards, .restakeRewards, .unlock, .revote: .action
        case .validationErrorEvent(let event): event.colorScheme
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .feeWillBeSubtractFromSendingAmount:
            return .init(iconType: .image(Assets.attention.image))
        case .approveTransactionInProgress:
            return .init(iconType: .progressView)
        case .unstake, .withdraw, .claimRewards, .restakeRewards, .unlock, .stakesWillMoveToNewValidator, .revote:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .validationErrorEvent(let event):
            return event.icon
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .networkUnreachable:
            return .critical
        case .approveTransactionInProgress,
             .unstake,
             .feeWillBeSubtractFromSendingAmount,
             .withdraw,
             .claimRewards,
             .restakeRewards,
             .unlock,
             .revote,
             .stakesWillMoveToNewValidator:
            return .info
        case .validationErrorEvent(let event):
            return event.severity
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .networkUnreachable:
            return .init(.refreshFee)
        case .validationErrorEvent(let event):
            return event.buttonAction
        case .approveTransactionInProgress,
             .unstake,
             .feeWillBeSubtractFromSendingAmount,
             .withdraw,
             .claimRewards,
             .restakeRewards,
             .unlock,
             .revote,
             .stakesWillMoveToNewValidator:
            return nil
        }
    }

    var isDismissable: Bool {
        false
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        true
    }
}
