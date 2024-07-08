//
//  OnboardingPushNotificationsViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingPushNotificationsViewModel: ObservableObject {
    private weak var delegate: OnboardingPushNotificationsDelegate?

    init(delegate: any OnboardingPushNotificationsDelegate) {
        self.delegate = delegate
    }

    func didTapAllow() {
        // TODO: https://tangem.atlassian.net/browse/IOS-6136
        delegate?.didFinishPushNotificationOnboarding()
    }

    func didTapLater() {
        delegate?.didFinishPushNotificationOnboarding()
    }
}
