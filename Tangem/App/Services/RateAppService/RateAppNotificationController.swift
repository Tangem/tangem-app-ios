//
//  RateAppNotificationController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol RateAppNotificationController {
    var showAppRateNotificationPublisher: AnyPublisher<Bool, Never> { get }

    func dismissAppRate()
}
