//
//  AddCustomTokenNotificationEvent.swift
//  Tangem
//
//  Created by Andrey Chukavin on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AddCustomTokenNotificationEvent: Hashable {
    case scamWarning
}

extension AddCustomTokenNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .scamWarning:
            return .string(Localization.customTokenValidationErrorNotFoundTitle)
        }
    }

    var description: String? {
        switch self {
        case .scamWarning:
            return Localization.customTokenValidationErrorNotFoundDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .scamWarning:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .scamWarning:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .scamWarning:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .scamWarning:
            return false
        }
    }

    var analyticsEvent: Analytics.Event? {
        switch self {
        case .scamWarning:
            return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .scamWarning:
            return [:]
        }
    }

    var isOneShotAnalyticsEvent: Bool {
        switch self {
        case .scamWarning:
            return false
        }
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }
}
