//
//  MarketsTokenModel.swift
//  Tangem
//
//  Created by skibinalexander on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenModel: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let currentPrice: Decimal?
    let priceChangePercentage: [String: Decimal]
    let marketRating: Int?
    let marketCap: Decimal?
    let isUnderMarketCapLimit: Bool?
}
