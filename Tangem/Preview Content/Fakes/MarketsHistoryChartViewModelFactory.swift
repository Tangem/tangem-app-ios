//
//  MarketsHistoryChartViewModelFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct MarketsHistoryChartViewModelFactory {
    func makeAll() -> MarketsHistoryChartViewModel {
        return MarketsHistoryChartViewModel(selectedPriceIntervalPublisher: Just(.all))
    }

    func makeHalfYear() -> MarketsHistoryChartViewModel {
        return MarketsHistoryChartViewModel(selectedPriceIntervalPublisher: Just(.halfYear))
    }

    func makeWeek() -> MarketsHistoryChartViewModel {
        return MarketsHistoryChartViewModel(selectedPriceIntervalPublisher: Just(.week))
    }
}
