//
//  MarketsTokenDetailsDateFormatterFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MarketsTokenDetailsDateFormatterFactory {
    static let shared = MarketsTokenDetailsDateFormatterFactory()

    private var notificationCenter: NotificationCenter { .default }
    private let cache = NSCacheWrapper<CacheKey, DateFormatter>()
    private var currentLocaleDidChangeSubscription: AnyCancellable?

    private init() {
        observeCurrentLocaleDidChangeNotification()
    }

    func makeXAxisDateFormatter(for intervalType: MarketsPriceIntervalType) -> DateFormatter {
        return getCachedOrMakeNewFormatter(
            cacheKey: .xAxis(intervalType: intervalType),
            dateFormatTemplate: makeXAxisDateFormatTemplate(for: intervalType)
        )
    }

    func makePriceDateFormatter(for intervalType: MarketsPriceIntervalType) -> DateFormatter {
        return getCachedOrMakeNewFormatter(
            cacheKey: .selectedChartValue(intervalType: intervalType),
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
        dateFormatter.locale = Locale.current
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

    private func observeCurrentLocaleDidChangeNotification() {
        currentLocaleDidChangeSubscription = notificationCenter
            .publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { factory, _ in
                factory.cache.removeAllObjects()
            }
    }
}

// MARK: - Auxiliary types

private extension MarketsTokenDetailsDateFormatterFactory {
    enum CacheKey: Hashable {
        case xAxis(intervalType: MarketsPriceIntervalType)
        case selectedChartValue(intervalType: MarketsPriceIntervalType)
    }
}
