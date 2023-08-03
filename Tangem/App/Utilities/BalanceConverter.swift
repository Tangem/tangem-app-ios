//
//  BalanceConverter.swift
//  Tangem
//
//  Created by Andrew Son on 03/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceConverter {
    @Injected(\.ratesRepository) private var ratesRepository: RatesRepository

    /// Converts from crypto to fiat using `RatesProvider`. If values doesn't loaded will wait for loading info from backend and return converted value
    /// Will throw error if failed to load rates or failed to find currency with specified code
    /// - Parameters:
    ///   - value: Amout of crypto to convert to fiat
    ///   - currencyId: ID of the crypto currency
    /// - Returns: Converted decimal value in specified fiat currency
    func convertToFiat(value: Decimal, from currencyId: String) async throws -> Decimal {
        let rate = try await ratesRepository.rate(for: currencyId)
        let fiatValue = value * rate
        return fiatValue
    }

    func convertToFiat(value: Decimal, from currencyId: String) -> Decimal? {
        guard let rate = ratesRepository.rates[currencyId] else {
            return nil
        }

        let fiatValue = value * rate
        return fiatValue
    }

    func convertFromFiat(value: Decimal, to currencyId: String) -> Decimal? {
        guard let rate = ratesRepository.rates[currencyId] else {
            return nil
        }

        let cryptoValue = value / rate
        return cryptoValue
    }
}
