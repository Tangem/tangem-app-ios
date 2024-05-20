//
//  BannerPromotionNotificationFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct BannerPromotionNotificationFactory {
    private static let travalaDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        return formatter
    }()

    func buildNotificationButton(
        actionType: NotificationButtonActionType,
        action: @escaping NotificationView.NotificationButtonTapAction
    ) -> NotificationView.NotificationButton {
        NotificationView.NotificationButton(action: action, actionType: actionType, isWithLoader: false)
    }

    func buildBannerNotificationInput(
        promotion: ActivePromotionInfo,
        button: NotificationView.NotificationButton?,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let event = event(for: promotion, place: .tokenDetails)
        return NotificationViewInput(
            style: button.map { .withButtons([$0]) } ?? .plain,
            severity: .info,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }
}

// MARK: - Private

private extension BannerPromotionNotificationFactory {
    func event(for promotion: ActivePromotionInfo, place: BannerPromotionPlacement) -> BannerNotificationEvent {
        switch promotion.bannerPromotion {
        case .travala:
            return .travala(description: travalaDescription(promotion: promotion))
        }
    }

    func travalaDescription(promotion: ActivePromotionInfo) -> String {
        Localization.mainTravalaPromotionDescription(
            Self.travalaDateFormatter.string(from: promotion.timeline.start),
            Self.travalaDateFormatter.string(from: promotion.timeline.end)
        )
    }
}
