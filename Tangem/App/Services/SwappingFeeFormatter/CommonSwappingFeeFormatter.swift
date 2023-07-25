//
//  CommonSwappingFeeFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct CommonSwappingFeeFormatter {
    private let fiatRatesProvider: FiatRatesProviding

    init(fiatRatesProvider: FiatRatesProviding) {
        self.fiatRatesProvider = fiatRatesProvider
    }
}

// MARK: - SwappingFeeFormatter

extension CommonSwappingFeeFormatter: SwappingFeeFormatter {
    func format(fee: Decimal, blockchain: SwappingBlockchain) async throws -> String {
        let fiatFee = try await fiatRatesProvider.getFiat(for: blockchain, amount: fee)
        return format(fee: fee, symbol: blockchain.symbol, fiatFee: fiatFee)
    }

    func format(fee: Decimal, blockchain: SwappingBlockchain) throws -> String {
        guard let fiatFee = fiatRatesProvider.getFiat(for: blockchain, amount: fee) else {
            throw CommonError.noData
        }

        return format(fee: fee, symbol: blockchain.symbol, fiatFee: fiatFee)
    }
}

// MARK: - Private

private extension CommonSwappingFeeFormatter {
    func format(fee: Decimal, symbol: String, fiatFee: Decimal) -> String {
        let feeFormatted = fee.groupedFormatted()
        let fiatFeeFormatted = fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)

        return "\(feeFormatted) \(symbol) (\(fiatFeeFormatted))"
    }
}
