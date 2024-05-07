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

    private func event(for promotion: ActivePromotionInfo, place: BannerPromotionPlace) -> BannerNotificationEvent {
        switch promotion.bannerPromotion {
        case .changelly:
            return .changelly(
                title: changellyTitle(place: place),
                description: changellyDescription(promotion: promotion, place: place)
            )
        case .travala:
            return .travala
        }
    }

    private func changellyTitle(place: BannerPromotionPlace) -> NotificationView.Title {
        let percent = changellyZeroPercent()
        let string: String = {
            switch place {
            case .main:
                return Localization.mainSwapChangellyPromotionTitle(percent)
            case .tokenDetails:
                return Localization.tokenSwapChangellyPromotionTitle(percent)
            }
        }()

        var attributed = AttributedString(string)
        attributed.font = Fonts.Bold.footnote
        attributed.foregroundColor = Colors.Text.constantWhite

        if let range = attributed.range(of: percent) {
            attributed[range.lowerBound...].foregroundColor = .init(red: 233, green: 253, blue: 2)
        }

        return .attributed(attributed)
    }

    func changellyDescription(promotion: ActivePromotionInfo, place: BannerPromotionPlace) -> String? {
        let percent = changellyZeroPercent()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"

        switch place {
        case .main:
            return Localization.mainSwapChangellyPromotionMessage(
                percent,
                formatter.string(from: promotion.timeline.start),
                formatter.string(from: promotion.timeline.end)
            )
        case .tokenDetails:
            return Localization.tokenSwapChangellyPromotionMessage(
                percent,
                formatter.string(from: promotion.timeline.start),
                formatter.string(from: promotion.timeline.end)
            )
        }
    }

    func changellyZeroPercent() -> String {
        let value = 0 as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        if let formatted = formatter.string(from: value) {
            return formatted
        }

        return "\(value)%"
    }
}
