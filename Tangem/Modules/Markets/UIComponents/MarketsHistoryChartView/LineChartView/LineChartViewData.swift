//
//  LineChartViewData.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct LineChartViewData: Equatable {
    struct YAxis: Equatable {
        let labelCount: Int
        let axisMinValue: Decimal
        let axisMaxValue: Decimal
    }

    struct XAxis: Equatable {
        struct Value: Equatable {
            /// In milliseconds.
            let timeStamp: UInt64
            let price: Decimal
        }

        let labelCount: Int
        let axisMinValue: Decimal
        let axisMaxValue: Decimal
        let values: [Value]
    }

    let yAxis: YAxis
    let xAxis: XAxis
}
