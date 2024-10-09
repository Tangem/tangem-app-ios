//
//  NotificationView+Settings.swift
//  Tangem
//
//  Created by Andrew Son on 15/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension NotificationView {
    typealias NotificationAction = (NotificationViewId) -> Void
    typealias NotificationButtonTapAction = (NotificationViewId, NotificationButtonActionType) -> Void

    /// Currently, this property isn't used in any way in the UI and acts more like a semantic attribute of the notification.
    /// - Note: Ideally should mimic standard UNIX syslog severity levels https://en.wikipedia.org/wiki/Syslog
    enum Severity {
        case info
        case warning
        case critical
    }

    struct Settings: Identifiable, Hashable {
        let event: any NotificationEvent
        let dismissAction: NotificationAction?

        var id: NotificationViewId { event.id }

        static func == (lhs: Settings, rhs: Settings) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct NotificationButton: Identifiable, Equatable {
        let action: NotificationButtonTapAction
        let actionType: NotificationButtonActionType
        let isWithLoader: Bool

        var id: Int { actionType.id }

        static func == (lhs: NotificationButton, rhs: NotificationButton) -> Bool {
            return lhs.actionType == rhs.actionType
        }
    }

    enum Style: Equatable {
        case tappable(action: NotificationAction)
        case withButtons([NotificationButton])
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

    enum Title: Hashable {
        case string(String)
        case attributed(AttributedString)
    }

    enum ColorScheme {
        case primary
        case secondary
        case action

        // Customs
        case ring

        @ViewBuilder
        var background: some View {
            switch self {
            case .primary: Colors.Background.primary
            case .secondary: Colors.Button.disabled
            case .action: Colors.Background.action
            case .ring:
                ZStack {
                    Assets.promoRingBg.image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .background(Color(hex: "#1E1E1E")!)
            }
        }

        @ViewBuilder
        var overlay: some View {
            switch self {
            case .ring:
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Assets.promoRingIcon.image
                            .resizable()
                            .frame(width: 60, height: 119)
                            .offset(CGSize(width: 0, height: 25.0))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                        Spacer()
                    }
                }
            default:
                EmptyView()
            }
        }

        var dismissButtonColor: Color {
            switch self {
            case .primary, .secondary, .action:
                return Colors.Icon.inactive
            case .ring:
                return Colors.Icon.informative
            }
        }

        var titleColor: Color {
            switch self {
            case .primary, .secondary, .action:
                return Colors.Text.primary1
            case .ring:
                return Colors.Text.constantWhite
            }
        }

        var messageColor: Color {
            switch self {
            case .primary, .secondary, .action, .ring:
                return Colors.Text.tertiary
            }
        }
    }

    enum LeadingIconType {
        case image(Image)
        case icon(TokenIconInfo)
        case progressView
        case placeholder
    }

    struct MessageIcon {
        let iconType: LeadingIconType
        var color: Color?
        var size: CGSize = .init(bothDimensions: 20)
    }
}
