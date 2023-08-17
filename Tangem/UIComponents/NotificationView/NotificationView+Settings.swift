//
//  NotificationView+Settings.swift
//  Tangem
//
//  Created by Andrew Son on 15/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension NotificationView {
    struct Settings: Identifiable, Hashable {
        let id: NotificationViewId = UUID().uuidString
        let colorScheme: NotificationView.ColorScheme
        let icon: NotificationView.MessageIcon
        let title: String
        let description: String?
        let isDismissable: Bool
        let dismissAction: ((NotificationViewId) -> Void)?

        static func == (lhs: Settings, rhs: Settings) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    enum Style: Equatable {
        case tappable(action: (NotificationViewId) -> Void)
        case withButtons([MainButton.Settings])
        case plain

        static func == (lhs: NotificationView.Style, rhs: NotificationView.Style) -> Bool {
            switch (lhs, rhs) {
            case (.tappable, .tappable): return true
            case (.plain, .plain): return true
            case (.withButtons(let lhsButtons), .withButtons(let rhsButtons)):
                return lhsButtons == rhsButtons
            default: return false
            }
        }
    }

    enum ColorScheme {
        case white
        case gray

        var color: Color {
            switch self {
            case .white: return Colors.Background.primary
            case .gray: return Colors.Button.secondary
            }
        }
    }

    struct MessageIcon {
        let image: Image
        var color: Color?
    }
}
