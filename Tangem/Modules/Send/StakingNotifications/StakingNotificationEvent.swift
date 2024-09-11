//
//  StakingNotificationEvent.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum StakingNotificationEvent {
    case stake(tokenSymbol: String, periodFormatted: String)
    case unstake(periodFormatted: String)
}

extension StakingNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        switch self {
        case .stake: "stake".hashValue
        case .unstake: "unstake".hashValue
        }
    }

    var title: NotificationView.Title {
        switch self {
        case .stake: .string(Localization.stakingNotificationEarnRewardsTitle)
        case .unstake: .string(Localization.commonUnstake)
        }
    }

    var description: String? {
        switch self {
        case .stake(let tokenSymbol, let periodFormatted):
            /*
             TODO: replace to
             staking_notification_earn_rewards_text_period_day
             staking_notification_earn_rewards_text_period_hour
             staking_notification_earn_rewards_text_period_month
             staking_notification_earn_rewards_text_period_week
             */
            return "UNDEFINED"
        //  return Localization.stakingNotificationEarnRewardsText(tokenSymbol, periodFormatted)
        case .unstake(let periodFormatted):
            return Localization.stakingNotificationUnstakeText(periodFormatted)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        .action
    }

    var icon: NotificationView.MessageIcon {
        return .init(iconType: .image(Assets.blueCircleWarning.image))
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
