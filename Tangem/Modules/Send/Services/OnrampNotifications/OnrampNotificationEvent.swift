//
//  OnrampNotificationEvent.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum OnrampNotificationEvent: Hashable {
    case refreshRequired(title: String, message: String)
}

extension OnrampNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .refreshRequired(let title, _):
            return .string(title)
        }
    }

    var description: String? {
        switch self {
        case .refreshRequired(_, let message):
            return message
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .refreshRequired:
            return .action
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .refreshRequired:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .refreshRequired:
            return .critical
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .refreshRequired:
            return .init(.refresh, withLoader: true)
        }
    }

    var isDismissable: Bool {
        false
    }

    // MARK: - Analytics

    var analyticsEvent: Analytics.Event? { nil }

    var analyticsParams: [Analytics.ParameterKey: String] { [:] }

    var isOneShotAnalyticsEvent: Bool { true }
}
