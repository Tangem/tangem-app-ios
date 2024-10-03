//
//  RateAppControllerStub.swift
//  Tangem
//
//  Created by Andrey Fedorov on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct RateAppControllerStub: RateAppInteractionController, RateAppNotificationController {
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    ) {}

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    ) {}

    func dismissAppRate() {}
    func openFeedbackMail() {}
    func openAppStoreReview() {}
}
