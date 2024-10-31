//
//  MarketsTokenDetailsMetrics.swift
//  Tangem
//
//  Created by Andrew Son on 10/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsMetrics: Codable, Equatable {
    let marketRating: Int?
    let circulatingSupply: Decimal?
    let marketCap: Decimal?
    let volume24H: Decimal?
    let totalSupply: Decimal?
    let maxSupply: Decimal?
    let fullyDilutedValuation: Decimal?
}
