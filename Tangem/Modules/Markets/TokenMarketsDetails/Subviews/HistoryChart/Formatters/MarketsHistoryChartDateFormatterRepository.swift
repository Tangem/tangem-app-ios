//
//  MarketsHistoryChartDateFormatterRepository.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Creates new (if needed) and caches existing `DateFormatter` instances.
final class MarketsHistoryChartDateFormatterRepository {
    static let shared = MarketsHistoryChartDateFormatterRepository()

    private let cache = NSCacheWrapper<CacheKey, DateFormatter>()

    private init() {}

    func dateFormatter(for intervalType: MarketsPriceIntervalType) -> DateFormatter {
        let locale = Locale.current
        let cacheKey = CacheKey(localeIdentifier: locale.identifier, intervalType: intervalType)

        if let cachedDateFormatter = cache.value(forKey: cacheKey) {
            return cachedDateFormatter
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale

        let dateFormatTemplate = makeDateFormatTemplate(for: intervalType)
        dateFormatter.setLocalizedDateFormatFromTemplate(dateFormatTemplate)

        cache.setValue(dateFormatter, forKey: cacheKey)

        return dateFormatter
    }

    private func makeDateFormatTemplate(for intervalType: MarketsPriceIntervalType) -> String {
        switch intervalType {
        case .day:
            "HH:mm"
        case .week,
             .month,
             .quarter,
             .halfYear:
            "dd MMM"
        case .year:
            "MMM"
        case .all:
            "yyyy"
        }
    }
}

// MARK: - Auxiliary types

private extension MarketsHistoryChartDateFormatterRepository {
    struct CacheKey: Hashable {
        let localeIdentifier: String
        let intervalType: MarketsPriceIntervalType
    }
}
