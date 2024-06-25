//
//  MarketsPriceIntervalType.swift
//  Tangem
//
//  Created by skibinalexander on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsPriceIntervalType: String, CaseIterable, Codable, CustomStringConvertible, Identifiable, Equatable {
    case day = "24h"
    case week = "7d"
    case month = "1m"

    var id: Self {
        self
    }

    var description: String {
        rawValue
    }
}
