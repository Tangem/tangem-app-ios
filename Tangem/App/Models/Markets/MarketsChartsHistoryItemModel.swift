//
//  MarketsChartsHistoryItemModel.swift
//  Tangem
//
//  Created by skibinalexander on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsChartsHistoryItemModel: Decodable {
    let prices: [String: Decimal]
}
