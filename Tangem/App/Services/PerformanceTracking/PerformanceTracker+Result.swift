//
//  PerformanceTracker+Result.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension PerformanceTracker {
    /// The result of tracking a metric.
    enum Result {
        case success
        case failure
        case unspecified
    }
}
