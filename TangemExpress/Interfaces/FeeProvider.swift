//
//  FeeProvider.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee
    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee
    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee
}

public enum ExpressAmount {
    /// Usual transfer for CEX
    case transfer(amount: Decimal)

    /// For `DEX` / `DEX/Bridge` operations
    case dex(txValue: Decimal, txData: Data)
}

public enum ExpressFee {
    case single(Fee)
    case double(market: Fee, fast: Fee)

    func fee(option: ExpressFeeOption) -> Fee {
        switch (self, option) {
        case (.double(_, let fast), .fast): fast
        case (.double(let market, _), .market): market
        case (.single(let fee), _): fee
        }
    }
}

public enum ExpressFeeOption: Hashable {
    case market
    case fast
}
