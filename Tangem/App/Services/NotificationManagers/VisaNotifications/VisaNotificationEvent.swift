//
//  VisaNotificationEvent.swift
//  Tangem
//
//  Created by Andrew Son on 16/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum VisaNotificationEvent: Hashable {
    case missingRequiredBlockchain
    case notValidBlockchain
    case failedToLoadPaymentAccount
    case missingPublicKey
    case failedToGenerateAddress
}

extension VisaNotificationEvent: NotificationEvent {
    var title: NotificationView.Title {
        .string("Error")
    }

    var description: String? {
        switch self {
        case .missingRequiredBlockchain:
            return "Failed to find required WalletManager"
        case .notValidBlockchain:
            return "WalletManager doesn't supported Smart Contract interaction"
        case .failedToLoadPaymentAccount:
            return "Failed to find Payment Account address in bridge"
        case .missingPublicKey:
            return "Failed to find Public key in keys repository"
        case .failedToGenerateAddress:
            return "Failed to generate address with provided Public key"
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        return .secondary
    }

    var icon: NotificationView.MessageIcon {
        return .init(iconType: .image(Assets.redCircleWarning.image))
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }

    var buttonAction: NotificationButtonAction? {
        nil
    }
}

// MARK: - Analytics

extension VisaNotificationEvent {
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
