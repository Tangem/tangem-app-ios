//
//  PushNotificationsAvailabilityProvider.swift
//  Tangem
//
//  Created by m3g0byt3 on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsAvailabilityProvider {
    var isAvailable: Bool { get }
}
