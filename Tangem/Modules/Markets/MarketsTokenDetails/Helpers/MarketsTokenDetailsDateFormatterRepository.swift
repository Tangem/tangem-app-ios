//
//  MarketsTokenDetailsDateFormatterRepository.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Creates new (if needed) and caches existing `DateFormatter` instances.
final class MarketsTokenDetailsDateFormatterRepository {
    static let shared = MarketsTokenDetailsDateFormatterRepository()

    private let cache = NSCacheWrapper<CacheKey, DateFormatter>()
    private var locale: Locale { .current }

    func xAxisDateFormatter(for intervalType: MarketsPriceIntervalType) -> DateFormatter {
        return getCachedOrMakeNewFormatter(
            cacheKey: .xAxis(localeIdentifier: locale.identifier, intervalType: intervalType),
            dateFormatTemplate: makeXAxisDateFormatTemplate(for: intervalType)
        )
    }

    func priceDateFormatter(for intervalType: MarketsPriceIntervalType) -> DateFormatter {
        return getCachedOrMakeNewFormatter(
            cacheKey: .selectedChartValue(localeIdentifier: locale.identifier, intervalType: intervalType),
            dateFormatTemplate: makePriceDateFormatTemplate(for: intervalType)
        )
    }

    private func getCachedOrMakeNewFormatter(
        cacheKey: CacheKey,
        dateFormatTemplate: @autoclosure () -> String
    ) -> DateFormatter {
        if let cachedDateFormatter = cache.value(forKey: cacheKey) {
            return cachedDateFormatter
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate(dateFormatTemplate())
        cache.setValue(dateFormatter, forKey: cacheKey)

        return dateFormatter
    }

    private func makeXAxisDateFormatTemplate(for intervalType: MarketsPriceIntervalType) -> String {
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

    private func makePriceDateFormatTemplate(for intervalType: MarketsPriceIntervalType) -> String {
        switch intervalType {
        case .day,
             .week,
             .month,
             .quarter:
            return "dd MMM HH:mm"
        case .halfYear,
             .year,
             .all:
            return "dd MMM yyyy"
        }
    }
}

// MARK: - Auxiliary types

private extension MarketsTokenDetailsDateFormatterRepository {
    enum CacheKey: Hashable {
        case xAxis(localeIdentifier: String, intervalType: MarketsPriceIntervalType)
        case selectedChartValue(localeIdentifier: String, intervalType: MarketsPriceIntervalType)
    }
}
