//
//  TokenMarketsDetailsModel.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsDetailsModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let isActive: Bool
    let currentPrice: Decimal
    let shortDescription: String?
    let fullDescription: String?
    let priceChangePercentage: [String: Decimal]
    let tokenItems: [TokenItem]
}
