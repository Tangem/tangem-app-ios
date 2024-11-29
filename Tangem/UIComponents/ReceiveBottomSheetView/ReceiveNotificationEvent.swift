//
//  ReceiveNotificationEvent.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 21.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ReceiveNotificationEvent {
    let currencySymbol: String
}

extension ReceiveNotificationEvent: NotificationEvent {
    var id: NotificationViewId {
        currencySymbol.hashValue
    }

    var title: NotificationView.Title {
        .string(Localization.receiveBottomSheetWarningMessageTitle(currencySymbol))
    }

    var description: String? {
        Localization.receiveBottomSheetWarningMessageDescription
    }

    var colorScheme: NotificationView.ColorScheme {
        .secondary
    }

    var icon: NotificationView.MessageIcon {
        .init(iconType: .image(Assets.blueCircleWarning.image))
    }

    var severity: NotificationView.Severity {
        .info
    }

    var isDismissable: Bool {
        false
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }

    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}
