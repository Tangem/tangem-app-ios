//
//  MarketsHistoryChartDateFormatterFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MarketsHistoryChartDateFormatterFactory {
    static let shared = MarketsHistoryChartDateFormatterFactory()

    private var notificationCenter: NotificationCenter { .default }
    private var cache = NSCacheWrapper<MarketsPriceIntervalType, DateFormatter>()
    private var bag: Set<AnyCancellable> = []

    private init() {
        observeCurrentLocaleDidChangeNotification()
    }

    func makeDateFormatter(for intervalType: MarketsPriceIntervalType) -> DateFormatter {
        if let cachedDateFormatter = cache.value(forKey: intervalType) {
            return cachedDateFormatter
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current

        let dateFormatTemplate = makeDateFormatTemplate(for: intervalType)
        dateFormatter.setLocalizedDateFormatFromTemplate(dateFormatTemplate)

        cache.setValue(dateFormatter, forKey: intervalType)

        return dateFormatter
    }

    private func observeCurrentLocaleDidChangeNotification() {
        notificationCenter
            .publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { factory, _ in
                factory.cache.removeAllObjects()
            }
            .store(in: &bag)
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
