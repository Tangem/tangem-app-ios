//
//  BannerNotificationEvent.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BannerNotificationEvent: Hashable, NotificationEvent {
    let title: NotificationView.Title
    let description: String?
    let programName: PromotionProgramName

    var colorScheme: NotificationView.ColorScheme {
        .okx
    }

    var icon: NotificationView.MessageIcon {
        .init(
            iconType: .image(Assets.okxDexLogoWhite.image.renderingMode(.template)),
            color: .white,
            size: .init(width: 49, height: 24)
        )
    }

    var severity: NotificationView.Severity {
        .info
    }

    var isDismissable: Bool {
        true
    }

    var analyticsEvent: Analytics.Event? {
        .promotionBannerAppeared
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .programName: Analytics.ParameterValue.okx.rawValue,
            .source: Analytics.ParameterValue.main.rawValue,
        ]
    }

    var isOneShotAnalyticsEvent: Bool {
        true
    }

    var id: NotificationViewId {
        programName.hashValue
    }
}
