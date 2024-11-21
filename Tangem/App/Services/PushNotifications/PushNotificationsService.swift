//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

final class PushNotificationsService: NSObject {
    /// - Note: Checks only explicit authorization (`UNAuthorizationStatus.authorized`) and ignores implicit
    /// authorization statuses such as `UNAuthorizationStatus.provisional` or `UNAuthorizationStatus.ephemeral`.
    @MainActor
    var isAuthorized: Bool {
        get async {
            let notificationSettings = await userNotificationCenter.notificationSettings()

            return notificationSettings.authorizationStatus == .authorized
        }
    }

    private let requestedAuthorizationOptions: UNAuthorizationOptions = [
        .alert,
        .badge,
        .sound,
    ]

    private let validAuthorizationStatuses: Set<UNAuthorizationStatus> = [
        .authorized,
        .ephemeral,
    ]

    private var userNotificationCenter: UNUserNotificationCenter { .current() }
    private let application: UIApplication

    init(application: UIApplication) {
        self.application = application
        super.init()
        userNotificationCenter.delegate = self
    }

    func requestAuthorizationAndRegister() async {
        do {
            if try await userNotificationCenter.requestAuthorization(options: requestedAuthorizationOptions) {
                await registerForRemoteNotifications()
            } else {
                AppLog.shared.error(
                    "Unable to request authorization and register for push notifications due to denied/undetermined authorization"
                )
            }
        } catch {
            AppLog.shared.error("Unable to request authorization and register for push notifications due to error:")
            AppLog.shared.error(error)
        }
    }

    func registerIfPossible() async {
        let notificationSettings = await userNotificationCenter.notificationSettings()
        if validAuthorizationStatuses.contains(notificationSettings.authorizationStatus) {
            await registerForRemoteNotifications()
        }
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        if !AppEnvironment.current.isDebug {
            application.registerForRemoteNotifications()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate protocol conformance

extension PushNotificationsService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        Analytics.log(.pushNotificationOpened)
    }
}
