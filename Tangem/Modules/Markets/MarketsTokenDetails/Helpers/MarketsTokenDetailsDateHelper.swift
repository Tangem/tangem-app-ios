//
//  MarketsTokenDetailsDateHelper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsDateHelper {
    private let initialDate: Date

    init(
        initialDate: Date
    ) {
        self.initialDate = initialDate
    }

    func makePriceDate(
        selectedDate: Date?,
        selectedPriceChangeIntervalType intervalType: MarketsPriceIntervalType
    ) -> String {
        switch (intervalType, selectedDate) {
        case (.day, .none):
            return Localization.commonToday
        case (.all, .none):
            return Localization.commonAll
        case (_, .none):
            let dateFormatter = MarketsTokenDetailsDateFormatterRepository.shared.priceDateFormatter(for: intervalType)
            let intervalBeginningDate = makeIntervalBeginningDate(using: intervalType)
            return makePriceDate(intervalBeginningDate: intervalBeginningDate, dateFormatter: dateFormatter)
        case (_, .some(let selectedDate)):
            let dateFormatter = MarketsTokenDetailsDateFormatterRepository.shared.priceDateFormatter(for: intervalType)
            return makePriceDate(intervalBeginningDate: selectedDate, dateFormatter: dateFormatter)
        }
    }

    private func makePriceDate(intervalBeginningDate: Date, dateFormatter: DateFormatter) -> String {
        return "\(dateFormatter.string(from: intervalBeginningDate)) – \(Localization.commonNow)"
    }

    private func makeIntervalBeginningDate(using selectedPriceChangeIntervalType: MarketsPriceIntervalType) -> Date {
        switch selectedPriceChangeIntervalType {
        case .week:
            return initialDate.dateByAdding(-7, .day).date
        case .month:
            return initialDate.dateByAdding(-1, .month).date
        case .quarter:
            return initialDate.dateByAdding(-3, .month).date
        case .halfYear:
            return initialDate.dateByAdding(-6, .month).date
        case .year:
            return initialDate.dateByAdding(-1, .year).date
        case .day,
             .all:
            assertionFailure("Unreachable")
            return Date()
        }
    }
}
