//
//  RateAppAction.swift
//  Tangem
//
//  Created by Andrey Fedorov on 18.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum RateAppAction {
    /// An in-app (not provided by System or StoreKit) dialog/alert/sheet/etc.
    case openAppRateDialog
    case openFeedbackMailWithEmailType(emailType: EmailType)
    case openAppStoreReview
}
