//
//  MarketsPriceIntervalType.swift
//  Tangem
//
//  Created by skibinalexander on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsPriceIntervalType: String, CaseIterable, Codable, Identifiable, Equatable {
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

    /// 24h/7d/1m/3m/6m/1y/All
    var analyticsParameterValue: String {
        switch self {
        case .day, .month, .quarter, .halfYear, .year:
            return rawValue
        case .week:
            return "7d"
        case .all:
            return "All"
        }
    }
}

// MARK: - Custom localized string representation

extension MarketsPriceIntervalType {
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

// MARK: - Custom serialization

extension MarketsPriceIntervalType {
    /// `/coins/history_preview` endpoint requires custom ids for some intervals.
    var marketsListId: String {
        switch self {
        case .month,
             .quarter,
             .halfYear,
             .year,
             .all:
            return "30d"
        case .day,
             .week:
            return rawValue
        }
    }

    /// `"/coins/{id}/history"` endpoint requires custom ids for some intervals.
    var historyChartId: String {
        switch self {
        case .all:
            return "all"
        case .day,
             .week,
             .month,
             .quarter,
             .halfYear,
             .year:
            return rawValue
        }
    }
}
