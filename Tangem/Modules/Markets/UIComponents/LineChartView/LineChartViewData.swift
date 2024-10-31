//
//  LineChartViewData.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct LineChartViewData: Equatable {
    enum Trend {
        case uptrend
        case downtrend
        case neutral
    }

    struct Value: Equatable {
        /// In milliseconds.
        let timeStamp: UInt64
        let price: Decimal
    }

    struct YAxis: Equatable {
        let labelCount: Int
        /// Axis min value, do not confuse with the min value of the data set.
        let axisMinValue: Decimal
        /// Axis max value, do not confuse with the max value of the data set.
        let axisMaxValue: Decimal
    }

    struct XAxis: Equatable {
        let labelCount: Int
        let values: [Value]
    }

    let trend: Trend
    let yAxis: YAxis
    let xAxis: XAxis
}
