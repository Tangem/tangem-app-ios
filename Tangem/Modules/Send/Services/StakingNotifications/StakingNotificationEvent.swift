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
    case restake
    case revote
    case unlock(periodFormatted: String)
    case validationErrorEvent(ValidationErrorEvent)
    case networkUnreachable
    case feeWillBeSubtractFromSendingAmount(cryptoAmountFormatted: String, fiatAmountFormatted: String)
    case stakesWillMoveToNewValidator(blockchain: String)
    case lowStakedBalance
    case maxAmountStaking
}

extension StakingNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .approveTransactionInProgress: "approveTransactionInProgress".hashValue
        case .feeWillBeSubtractFromSendingAmount(let cryptoAmountFormatted, _): "feeWillBeSubtractFromSendingAmount \(cryptoAmountFormatted)".hashValue
        case .unstake: "unstake".hashValue
        case .withdraw: "withdraw".hashValue
        case .claimRewards: "claimRewards".hashValue
        case .restakeRewards: "restakeRewards".hashValue
        case .restake: "restake".hashValue
        case .revote: "revote".hashValue
        case .unlock: "unlock".hashValue
        case .validationErrorEvent(let validationErrorEvent): validationErrorEvent.id
        case .networkUnreachable: "networkUnreachable".hashValue
        case .stakesWillMoveToNewValidator: "stakesWillMoveToNewValidator".hashValue
        case .lowStakedBalance: "lowStakedBalance".hashValue
        case .maxAmountStaking: "maxAmountStaking".hashValue
        }
    }

    var title: NotificationView.Title {
        switch self {
        case .approveTransactionInProgress: .string(Localization.warningExpressApprovalInProgressTitle)
        case .feeWillBeSubtractFromSendingAmount: .string(Localization.sendNetworkFeeWarningTitle)
        case .unstake: .string(Localization.commonUnstake)
        case .withdraw: .string(Localization.stakingWithdraw)
        case .claimRewards: .string(Localization.commonClaim)
        case .restakeRewards: .string(Localization.stakingRestakeRewards)
        case .restake: .string(Localization.stakingRestake)
        case .revote: .string(Localization.stakingRevote)
        case .unlock: .string(Localization.stakingUnlockedLocked)
        case .validationErrorEvent(let event): event.title
        case .networkUnreachable: .string(Localization.sendFeeUnreachableErrorTitle)
        case .stakesWillMoveToNewValidator: .string(Localization.stakingRevote)
        case .lowStakedBalance: .string(Localization.stakingNotificationLowStakedBalanceTitle)
        case .maxAmountStaking: .string(Localization.commonNetworkFeeTitle)
        }
    }

    var description: String? {
        switch self {
        case .approveTransactionInProgress:
            Localization.warningApprovalInProgressMessage
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
        case .restake:
            Localization.stakingNotificationRestakeText
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
        case .lowStakedBalance:
            Localization.stakingNotificationLowStakedBalanceText
        case .maxAmountStaking:
            Localization.stakingNotificationStakeEntireBalanceText
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .approveTransactionInProgress, .feeWillBeSubtractFromSendingAmount,
             .stakesWillMoveToNewValidator, .lowStakedBalance:
            .secondary
        case .unstake, .networkUnreachable, .withdraw, .claimRewards,
             .restakeRewards, .restake, .unlock, .revote, .maxAmountStaking:
            .action
        case .validationErrorEvent(let event): event.colorScheme
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkUnreachable, .feeWillBeSubtractFromSendingAmount, .lowStakedBalance:
            return .init(iconType: .image(Assets.attention.image))
        case .approveTransactionInProgress:
            return .init(iconType: .progressView)
        case .unstake, .withdraw, .claimRewards, .restakeRewards, .restake,
             .unlock, .stakesWillMoveToNewValidator, .revote, .maxAmountStaking:
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
             .restake,
             .unlock,
             .revote,
             .lowStakedBalance,
             .maxAmountStaking,
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
             .restake,
             .unlock,
             .revote,
             .lowStakedBalance,
             .maxAmountStaking,
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
