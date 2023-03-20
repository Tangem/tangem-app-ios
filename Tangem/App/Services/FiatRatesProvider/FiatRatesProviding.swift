//
//  FiatRatesProviding.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

protocol FiatRatesProviding {
    func hasRates(for currency: Currency) -> Bool
    func hasRates(for blockchain: ExchangeBlockchain) -> Bool
    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal
    func getFiat(for blockchain: ExchangeBlockchain, amount: Decimal) async throws -> Decimal
}
