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
    private let highPriceImpactWarningLimit: Decimal = 10

    func isHighPriceImpact(converting sourceAmount: Decimal, to destinationAmount: Decimal) async throws -> Bool {
        let sourceFiatAmount = try await balanceConverter.convertToFiat(value: sourceAmount, from: sourceCurrencyId)
        let destinationFiatAmount = try await balanceConverter.convertToFiat(value: destinationAmount, from: destinationCurrencyId)

        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount) * 100

        let isHighPriceImpact = lossesInPercents >= highPriceImpactWarningLimit
        return isHighPriceImpact
    }
}
