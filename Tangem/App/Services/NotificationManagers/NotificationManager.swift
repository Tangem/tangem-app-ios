//
//  NotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 26/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol NotificationManager: AnyObject {
    var notificationInputs: [NotificationViewInput] { get }
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> { get }

    func setupManager(with delegate: NotificationTapDelegate?)
    func dismissNotification(with id: NotificationViewId)
}
