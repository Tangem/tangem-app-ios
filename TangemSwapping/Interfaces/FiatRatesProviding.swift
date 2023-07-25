//
//  FiatRatesProviding.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool
    func hasRates(for blockchain: SwappingBlockchain) -> Bool

    func getFiat(for currency: Currency, amount: Decimal) -> Decimal?
    func getFiat(for blockchain: SwappingBlockchain, amount: Decimal) -> Decimal?

    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal
    func getFiat(for blockchain: SwappingBlockchain, amount: Decimal) async throws -> Decimal

    func getFiat(for currencies: [Currency: Decimal]) async throws -> [Currency: Decimal]
}
