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
    case all = "all_time"

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

    var tokenDetailsNameLocalized: String {
        switch self {
        case .day: return Localization.marketsSelectorInterval24hTitle
        case .week: return Localization.marketsSelectorInterval7dTitle
        case .month: return Localization.marketsSelectorInterval1mTitle
        case .quarter: return Localization.marketsSelectorInterval3mTitle
        case .halfYear: return Localization.marketsSelectorInterval6mTitle
        case .year: return Localization.marketsSelectorInterval1yTitle
        case .all: return Localization.marketsSelectorIntervalAllTitle
        }
    }
}
