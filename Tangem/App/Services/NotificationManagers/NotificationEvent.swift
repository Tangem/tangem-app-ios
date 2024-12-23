//
//  NotificationEvent.swift
//  Tangem
//
//  Created by Andrew Son on 04/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol NotificationEvent: Identifiable {
    var id: NotificationViewId { get }
    var title: NotificationView.Title? { get }
    var description: String? { get }
    var colorScheme: NotificationView.ColorScheme { get }
    var icon: NotificationView.MessageIcon { get }
    var severity: NotificationView.Severity { get }
    var isDismissable: Bool { get }
    var buttonAction: NotificationButtonAction? { get }
    // TODO: Discuss analytics refactoring, probably we should combine all related data into single struct
    var analyticsEvent: Analytics.Event? { get }
    var analyticsParams: [Analytics.ParameterKey: String] { get }
    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { get }
}

extension NotificationEvent where Self: Hashable {
    // Unique ID. Overwrite if hash value is not enough (may be influenced by associated values)
    var id: NotificationViewId {
        hashValue
    }
}
