//
//  AnalyticsStorageKey.swift
//  Tangem
//
//  Created by Alexander Osokin on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AnalyticsStorageKey: String {
    case hasPositiveBalance
    case scanSource
    case limitedEvents

    var isPermanent: Bool {
        switch self {
        case .hasPositiveBalance:
            return true
        case .scanSource, .limitedEvents:
            return false
        }
    }
}
