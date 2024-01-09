//
//  NotificationEvent.swift
//  Tangem
//
//  Created by Andrew Son on 04/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol NotificationEvent: Hashable {
    var title: String { get }
    var description: String? { get }
    var colorScheme: NotificationView.ColorScheme { get }
    var icon: NotificationView.MessageIcon { get }
    var severity: NotificationView.Severity { get }
    var isDismissable: Bool { get }
    // TODO: Discuss analytics refactoring, probably we should combine all related data into single struct
    var analyticsEvent: Analytics.Event? { get }
    var analyticsParams: [Analytics.ParameterKey: String] { get }
    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { get }
}
