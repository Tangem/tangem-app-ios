//
//  PerformanceTracker+Metric.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension PerformanceTracker {
    /// The metric to track.
    enum Metric {
        case totalBalanceLoaded(tokensCount: Int)
    }
}
