//
//  RateAppInteractionController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol RateAppInteractionController {
    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher1: some Publisher<[NotificationViewInput], Never>,
        notificationsPublisher2: some Publisher<[NotificationViewInput], Never>
    )

    func bind(
        isPageSelectedPublisher: some Publisher<Bool, Never>,
        notificationsPublisher: some Publisher<[NotificationViewInput], Never>
    )

    func openFeedbackMail()

    func openAppStoreReview()
}
