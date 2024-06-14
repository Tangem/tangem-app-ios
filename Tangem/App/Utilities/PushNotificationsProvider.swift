//
//  PushNotificationsProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum PushNotificationsProvider {
    static var isAvailable: Bool {
        // TODO: https://tangem.atlassian.net/browse/IOS-6136
        FeatureProvider.isAvailable(.pushNotifications)
    }
}
