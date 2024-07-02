//
//  MarketsPriceIntervalType.swift
//  Tangem
//
//  Created by skibinalexander on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsPriceIntervalType: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Equatable {
    case day = "24h"
    case week = "1w"
    case month = "1m"
    case quarter = "3m"
    case halfYear = "6m"
    case year = "1y"
    case all

    var id: String {
        rawValue
    }

    var marketsListId: String {
        switch self {
        case .day: return "24h"
        case .week: return "1w"
        default: return "30d"
        }
    }
}
