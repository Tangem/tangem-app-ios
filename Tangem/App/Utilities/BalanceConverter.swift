//
//  BalanceConverter.swift
//  Tangem
//
//  Created by Andrew Son on 03/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceConverter {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    /// Converts from crypto to fiat using `RatesProvider`. If values doesn't loaded will wait for loading info from backend and return converted value
    /// Will throw error if failed to load quotes or failed to find currency with specified code
    /// - Parameters:
    ///   - value: Amout of crypto to convert to fiat
    ///   - currencyId: ID of the crypto currency
    /// - Returns: Converted decimal value in specified fiat currency
    func convertToFiat(_ value: Decimal, currencyId: String) async throws -> Decimal {
        let rate = try await quotesRepository.quote(for: currencyId).price
        let fiatValue = value * rate
        return fiatValue
    }

    func convertToFiat(_ value: Decimal, currencyId: String) -> Decimal? {
        guard let rate = quotesRepository.quotes[currencyId]?.price else {
            return nil
        }

        let fiatValue = value * rate
        return fiatValue
    }

    func convertFromFiat(_ value: Decimal, currencyId: String) -> Decimal? {
        guard let rate = quotesRepository.quotes[currencyId]?.price else {
            return nil
        }

        let cryptoValue = value / rate
        return cryptoValue
    }
}
