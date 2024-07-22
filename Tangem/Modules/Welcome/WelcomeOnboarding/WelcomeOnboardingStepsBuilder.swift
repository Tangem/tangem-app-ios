//
//  WelcomeOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboardingStepsBuilder {
    private let isPushNotificationsAvailable: Bool

    init(
        isPushNotificationsAvailable: Bool
    ) {
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
    }

    func buildSteps() -> [WelcomeOnboardingStep] {
        var steps = [WelcomeOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(AppConstants.tosURL.absoluteString) {
            steps.append(.tos)
        }

        if isPushNotificationsAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }
}
