//
//  NotificationViewInput.swift
//  Tangem
//
//  Created by Andrew Son on 15/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

typealias NotificationViewId = String

struct NotificationViewInput: Identifiable, Equatable {
    let style: NotificationView.Style
    let settings: NotificationView.Settings

    var id: NotificationViewId { settings.id }

    static func == (lhs: NotificationViewInput, rhs: NotificationViewInput) -> Bool {
        lhs.settings == rhs.settings
    }
}
