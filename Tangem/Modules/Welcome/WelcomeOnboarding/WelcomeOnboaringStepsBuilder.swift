//
//  WelcomeOnboaringStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboaringStepsBuilder {
    private let isPushNotificationsAvailable: Bool

    init(
        isPushNotificationsAvailable: Bool
    ) {
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
    }

    func buildSteps() -> [WelcomeOnbordingStep] {
        var steps = [WelcomeOnbordingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(AppConstants.tosURL.absoluteString) {
            steps.append(.tos)
        }

        if isPushNotificationsAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }
}
