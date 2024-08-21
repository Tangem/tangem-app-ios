//
//  PushNotificationsPermissionRequestDelegate.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsPermissionRequestDelegate: AnyObject {
    func didFinishPushNotificationOnboarding()
}
