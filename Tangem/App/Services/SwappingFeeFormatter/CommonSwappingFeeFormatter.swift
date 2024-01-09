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
    private let balanceFormatter: BalanceFormatter
    private let balanceConverter: BalanceConverter

    private let fiatRatesProvider: FiatRatesProviding // Will be deleted

    init(
        balanceFormatter: BalanceFormatter,
        balanceConverter: BalanceConverter,
        fiatRatesProvider: FiatRatesProviding
    ) {
        self.balanceFormatter = balanceFormatter
        self.balanceConverter = balanceConverter
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

    func format(fee: Decimal, tokenItem: TokenItem) -> String {
        let currencySymbol = tokenItem.blockchain.currencySymbol
        let currencyId = tokenItem.blockchain.currencyId
        let feeFormatted = balanceFormatter.formatCryptoBalance(fee, currencyCode: currencySymbol)

        guard let fiatFee = balanceConverter.convertToFiat(value: fee, from: currencyId) else {
            return feeFormatted
        }

        let fiatFeeFormatted = balanceFormatter.formatFiatBalance(fiatFee)
        let result = "\(feeFormatted) (\(fiatFeeFormatted))"
        if fee > 0, tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType) {
            return "< " + result
        } else {
            return result
        }
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
