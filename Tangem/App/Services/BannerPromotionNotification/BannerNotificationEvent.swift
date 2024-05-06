//
//  BannerNotificationEvent.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum BannerNotificationEvent: Hashable, NotificationEvent {
    case changelly(title: NotificationView.Title, description: String?)
    case travala

    var title: NotificationView.Title {
        switch self {
        case .travala:
            return .string("Book your holidays with Tangem and pay in crypto")
        case .changelly(let title, _):
            return title
        }
    }

    var description: String? {
        switch self {
        case .changelly(_, let description):
            return description
        case .travala:
            return "Save 50 USDT while booking via our partner Travala"
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .changelly:
            return .changellyPromotion
        case .travala:
            return .travalaPromotion
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .changelly:
            return .init(
                iconType: .image(Assets.swapBannerIcon.image),
                size: CGSize(bothDimensions: 34)
            )
        case .travala:
            return .init(
                iconType: .image(Assets.swapBannerIcon.image), // TODO:
                size: CGSize(bothDimensions: 34)
            )
        }
    }

    var severity: NotificationView.Severity { .info }
    var isDismissable: Bool { true }
    var analyticsEvent: Analytics.Event? { nil }
    var analyticsParams: [Analytics.ParameterKey: String] { [:] }
    var isOneShotAnalyticsEvent: Bool { true }
}
