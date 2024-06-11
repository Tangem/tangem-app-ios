//
//  RateAppAction.swift
//  Tangem
//
//  Created by Andrey Fedorov on 18.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Service to controller commands.
enum RateAppAction {
    case requestAppRate
    case dismissAppRate
    case openFeedbackMailWithEmailType(emailType: EmailType)
    case openAppStoreReview
}
