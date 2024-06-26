//
//  HighPriceImpactCalculator.swift
//  Tangem
//
//  Created by Andrew Son on 23/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct HighPriceImpactCalculator {
    let sourceCurrencyId: String
    let destinationCurrencyId: String

    private let balanceConverter = BalanceConverter()
    // 10% in the 0..1 range
    private let highPriceImpactWarningLimit: Decimal = 0.1

    func isHighPriceImpact(converting sourceAmount: Decimal, to destinationAmount: Decimal) async throws -> Result {
        let sourceFiatAmount = try await balanceConverter.convertToFiat(value: sourceAmount, from: sourceCurrencyId)
        let destinationFiatAmount = try await balanceConverter.convertToFiat(value: destinationAmount, from: destinationCurrencyId)

        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount)

        let isHighPriceImpact = lossesInPercents >= highPriceImpactWarningLimit
        return Result(lossesInPercents: lossesInPercents, isHighPriceImpact: isHighPriceImpact)
    }
}

extension HighPriceImpactCalculator {
    struct Result {
        let lossesInPercents: Decimal
        let isHighPriceImpact: Bool
    }
}
