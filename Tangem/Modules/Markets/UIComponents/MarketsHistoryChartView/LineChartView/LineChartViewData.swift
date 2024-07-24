//
//  LineChartViewData.swift
//  ChartComponent
//
//  Created by m3g0byt3 on 23.07.2024.
//

import Foundation

struct LineChartViewData: Equatable {
    struct YAxis: Equatable {
        let minValue: Double
        let maxValue: Double
    }

    struct XAxis: Equatable {
        struct Value: Equatable {
            /// In microseconds.
            let timeStamp: UInt64
            let price: Double
        }

        let values: [Value]
    }

    let yAxis: YAxis
    let xAxis: XAxis
}
