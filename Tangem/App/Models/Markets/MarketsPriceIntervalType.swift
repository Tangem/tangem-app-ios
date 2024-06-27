//
//  MarketsPriceIntervalType.swift
//  Tangem
//
//  Created by skibinalexander on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsPriceIntervalType: CaseIterable, Codable, CustomStringConvertible, Identifiable, Equatable {
    case day
    case week
    case month
    case quarter
    case halfYear
    case year
    case all

    var id: String {
        tokenMarketsDetailsId
    }

    var marketsListId: String {
        switch self {
        case .day: return "24h"
        case .week: return "1w"
        default: return "30d"
        }
    }

    var tokenMarketsDetailsId: String {
        switch self {
        case .day: return "24h"
        case .week: return "1w"
        case .month: return "1m"
        case .quarter: return "3m"
        case .halfYear: return "6m"
        case .year: return "1y"
        case .all: return "all"
        }
    }
}
