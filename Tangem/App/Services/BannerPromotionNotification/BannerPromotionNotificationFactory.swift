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

    func buildBannerNotificationInput(
        promotion: ActivePromotionInfo,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let style: NotificationView.Style
        let severity: NotificationView.Severity
        let settings: NotificationView.Settings

        switch promotion.bannerPromotion {
        case .travala:
            severity = .info

            let event = BannerNotificationEvent.travala(
                description: travalaDescription(promotion: promotion),
                programName: promotion.bannerPromotion
            )

            settings = .init(event: event, dismissAction: dismissAction)

            if let link = promotion.link {
                let button = NotificationView.NotificationButton(
                    action: buttonAction,
                    actionType: .bookNow(promotionLink: link),
                    isWithLoader: false
                )
                style = .withButtons([button])
            } else {
                style = .plain
            }
        }

        return NotificationViewInput(
            style: style,
            severity: severity,
            settings: settings
        )
    }
}

// MARK: - Private

private extension BannerPromotionNotificationFactory {
    func travalaDescription(promotion: ActivePromotionInfo) -> String {
        Localization.mainTravalaPromotionDescription(
            Self.travalaDateFormatter.string(from: promotion.timeline.start),
            Self.travalaDateFormatter.string(from: promotion.timeline.end)
        )
    }
}
