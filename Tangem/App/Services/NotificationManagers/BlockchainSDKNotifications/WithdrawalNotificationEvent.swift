//
//  WithdrawalNotificationEvent.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

// Warning/Information Notifications
enum WithdrawalNotificationEvent: Hashable {
    case reduceAmountBecauseFeeIsTooHigh(amount: Decimal, amountFormatted: String, blockchainName: String)
    case cardanoWillBeSendAlongToken(cardanoAmountFormatted: String, tokenSymbol: String)
}

extension WithdrawalNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        switch self {
        case .reduceAmountBecauseFeeIsTooHigh:
            return .string(Localization.sendNotificationHighFeeTitle)
        case .cardanoWillBeSendAlongToken:
            return .string(Localization.cardanoCoinWillBeSendWithTokenTitle)
        }
    }

    var description: String? {
        switch self {
        case .reduceAmountBecauseFeeIsTooHigh(_, let amount, let blockchainName):
            return Localization.sendNotificationHighFeeText(blockchainName, amount)
        case .cardanoWillBeSendAlongToken(let cardanoAmountFormatted, let tokenSymbol):
            return Localization.cardanoCoinWillBeSendWithTokenDescription(cardanoAmountFormatted, tokenSymbol)
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        let hasButton = buttonAction != nil
        if hasButton {
            return .action
        }

        return .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .reduceAmountBecauseFeeIsTooHigh,
             .cardanoWillBeSendAlongToken:
            return .init(iconType: .image(Assets.attention.image))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .reduceAmountBecauseFeeIsTooHigh,
             .cardanoWillBeSendAlongToken:
            return .warning
        }
    }

    var isDismissable: Bool {
        return false
    }
}

// MARK: Button

extension WithdrawalNotificationEvent {
    var buttonAction: NotificationButtonAction? {
        switch self {
        case .reduceAmountBecauseFeeIsTooHigh(let amount, let amountFormatted, _):
            return .init(.reduceAmountBy(amount: amount, amountFormatted: amountFormatted))
        case .cardanoWillBeSendAlongToken:
            return nil
        }
    }
}

// MARK: Analytics

extension WithdrawalNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        return nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        return [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        return false
    }
}
