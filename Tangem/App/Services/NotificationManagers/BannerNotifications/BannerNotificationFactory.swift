//
//  BannerNotificationFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BannerNotificationFactory {
    func buildBannerNotificationInput(
        promotion: ActivePromotionInfo,
        placement: BannerPromotionPlacement,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        let style: NotificationView.Style
        let severity: NotificationView.Severity
        let settings: NotificationView.Settings

        switch promotion.bannerPromotion {
        case .ring:
            severity = .info

            let event = BannerNotificationEvent(
                title: .string(Localization.ringPromoTitle),
                description: Localization.ringPromoText,
                programName: promotion.bannerPromotion,
                placement: placement,
                icon: .init(
                    iconType: .placeholder,
                    size: .init(bothDimensions: 60)
                ),
                colorScheme: .ring,
                severity: .info
            )

            settings = .init(event: event, dismissAction: dismissAction)

            // For future banners
            if let link = promotion.link {
                let button = NotificationView.NotificationButton(
                    action: buttonAction,
                    actionType: .openLink(promotionLink: link, buttonTitle: ""),
                    isWithLoader: false
                )

                style = .withButtons([button])
            } else {
                switch placement {
                case .main:
                    style = .plain
                case .tokenDetails:
                    let button = NotificationView.NotificationButton(
                        action: buttonAction,
                        actionType: .swap,
                        isWithLoader: false
                    )

                    style = .withButtons([button])
                }
            }
        }

        return NotificationViewInput(
            style: style,
            severity: severity,
            settings: settings
        )
    }
}
