//
//  NotificationsAnalyticsService.swift
//  Tangem
//
//  Created by Andrew Son on 02/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class NotificationsAnalyticsService {
    private weak var notificationManager: NotificationManager?
    private weak var contextDataProvider: AnalyticsContextDataProvider?

    private var subscription: AnyCancellable?
    private var alreadyTrackedEvents: Set<Analytics.Event> = []

    init() {}

    func setup(with notificationManager: NotificationManager, contextDataProvider: AnalyticsContextDataProvider?) {
        self.notificationManager = notificationManager
        self.contextDataProvider = contextDataProvider

        bind()
    }

    private func bind() {
        guard subscription == nil else {
            return
        }

        subscription = notificationManager?.notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: NotificationsAnalyticsService.sendEventsIfNeeded(for:)))
    }

    private func sendEventsIfNeeded(for notifications: [NotificationViewInput]) {
        notifications.forEach(sendEventIfNeeded(for:))
    }

    private func sendEventIfNeeded(for notification: NotificationViewInput) {
        let event = notification.settings.event
        guard let analyticsEvent = event.analyticsEvent else {
            return
        }

        var notificationParams = notification.settings.event.analyticsParams
        if let contextData = contextDataProvider?.getAnalyticsContextData() {
            notificationParams.merge(contextData.analyticsParams, uniquingKeysWith: { old, new in old })
        }

        if event.isOneShotAnalyticsEvent, alreadyTrackedEvents.contains(analyticsEvent) {
            return
        }

        Analytics.log(event: analyticsEvent, params: notificationParams)

        if event.isOneShotAnalyticsEvent {
            alreadyTrackedEvents.insert(analyticsEvent)
        }
    }
}
