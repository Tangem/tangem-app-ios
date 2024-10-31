//
//  MarketsPricePerformanceData.swift
//  Tangem
//
//  Created by Andrew Son on 11/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsPricePerformanceData: Codable, Equatable {
    let lowPrice: Decimal?
    let highPrice: Decimal?
}
