//
//  NotificationsFactory.swift
//  Tangem
//
//  Created by Andrew Son on 14/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NotificationsFactory {
    func buildNotificationInputs(
        for events: [GeneralNotificationEvent],
        action: @escaping NotificationView.NotificationAction,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> [NotificationViewInput] {
        return events.map { event in
            buildNotificationInput(
                for: event,
                action: action,
                buttonAction: buttonAction,
                dismissAction: dismissAction
            )
        }
    }

    func buildNotificationInput(
        for event: GeneralNotificationEvent,
        action: @escaping NotificationView.NotificationAction,
        buttonAction: @escaping NotificationView.NotificationButtonTapAction,
        dismissAction: @escaping NotificationView.NotificationAction
    ) -> NotificationViewInput {
        return NotificationViewInput(
            style: event.style(tapAction: action, buttonAction: buttonAction),
            severity: event.severity,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    func buildNotificationInput<Event: NotificationEvent>(
        for event: Event,
        buttonAction: NotificationView.NotificationButtonTapAction? = nil,
        dismissAction: NotificationView.NotificationAction? = nil
    ) -> NotificationViewInput {
        return .init(
            style: notificationStyle(for: event, action: buttonAction),
            severity: event.severity,
            settings: .init(event: event, dismissAction: dismissAction)
        )
    }

    private func notificationStyle<Event: NotificationEvent>(
        for event: Event,
        action: NotificationView.NotificationButtonTapAction?
    ) -> NotificationView.Style {
        guard let action, let buttonAction = event.buttonAction else {
            return .plain
        }

        return .withButtons([
            .init(action: action, actionType: buttonAction.type, isWithLoader: buttonAction.withLoader),
        ])
    }
}
