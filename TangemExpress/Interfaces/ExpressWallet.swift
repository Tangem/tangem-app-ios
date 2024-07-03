//
//  ExpressWallet.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressWallet {
    var expressCurrency: ExpressCurrency { get }
    var defaultAddress: String { get }
    var decimalCount: Int { get }
    var isFeeCurrency: Bool { get }
    var feeCurrencyHasPositiveBalance: Bool { get }

    func getBalance() throws -> Decimal
    func feeCurrencyEnoughBalanceToSend(value: Decimal) -> Bool
}

public extension ExpressWallet {
    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
