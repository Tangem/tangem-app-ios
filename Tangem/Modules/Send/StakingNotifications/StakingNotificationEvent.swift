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
    case stake(tokenSymbol: String, rewardScheduleType: RewardScheduleType)
    case unstake(periodFormatted: String)
}

extension StakingNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .approveTransactionInProgress: "approveTransactionInProgress".hashValue
        case .stake: "stake".hashValue
        case .unstake: "unstake".hashValue
        }
    }

    var title: NotificationView.Title {
        switch self {
        case .approveTransactionInProgress: .string(Localization.warningExpressApprovalInProgressTitle)
        case .stake: .string(Localization.stakingNotificationEarnRewardsTitle)
        case .unstake: .string(Localization.commonUnstake)
        }
    }

    var description: String? {
        switch self {
        case .approveTransactionInProgress:
            Localization.warningExpressApprovalInProgressMessage
        case .stake(let tokenSymbol, .hour):
            Localization.stakingNotificationEarnRewardsTextPeriodHour(tokenSymbol)
        case .stake(let tokenSymbol, .day):
            Localization.stakingNotificationEarnRewardsTextPeriodDay(tokenSymbol)
        case .stake(let tokenSymbol, .week):
            Localization.stakingNotificationEarnRewardsTextPeriodWeek(tokenSymbol)
        case .stake(let tokenSymbol, .month):
            Localization.stakingNotificationEarnRewardsTextPeriodMonth(tokenSymbol)
        case .unstake(let periodFormatted):
            Localization.stakingNotificationUnstakeText(periodFormatted)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .approveTransactionInProgress: .secondary
        case .stake, .unstake: .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .approveTransactionInProgress:
            return .init(iconType: .progressView)
        case .stake, .unstake:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        .info
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
