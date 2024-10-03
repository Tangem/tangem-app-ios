//
//  Analytics+EventLimit.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum EventLimit {
        // One time per app session. Use extraEventId to limit repeating events with different params
        case appSession(extraEventId: String? = nil)
        // One time per app session and per user wallet. Use extraEventId to limit repeating events with different params
        case userWalletSession(userWalletId: UserWalletId, extraEventId: String? = nil)
        // No limits
        case unlimited
    }
}

extension Analytics.EventLimit {
    var isLimited: Bool {
        switch self {
        case .appSession, .userWalletSession:
            return true
        case .unlimited:
            return false
        }
    }

    var extraEventId: String? {
        switch self {
        case .appSession(let extraEventId):
            return extraEventId
        case .userWalletSession(_, let extraEventId):
            return extraEventId
        case .unlimited:
            return nil
        }
    }

    var contextScope: AnalyticsContextScope {
        switch self {
        case .appSession, .unlimited:
            return .common
        case .userWalletSession(let userWalletId, _):
            return .userWallet(userWalletId)
        }
    }
}
