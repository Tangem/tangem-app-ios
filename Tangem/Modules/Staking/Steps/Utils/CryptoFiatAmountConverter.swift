//
//  CryptoFiatAmountConverter.swift
//  Tangem
//
//  Created by Sergey Balashov on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CryptoFiatAmountConverter {
    private let formatter: DecimalNumberFormatter

    init() {
        formatter = DecimalNumberFormatter(maximumFractionDigits: AppConstants.maximumFractionDigitsForBalance)
    }

    func convertToCrypto(_ fiatValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
//        if cached?.fiat == fiatValue {
//            return cached?.crypto
//        }

        guard let fiatValue,
              let currencyId = tokenItem.currencyId,
              let cryptoValue = BalanceConverter().convertFromFiat(fiatValue, currencyId: currencyId) else {
            return nil
        }

        formatter.update(maximumFractionDigits: tokenItem.decimalCount)
        return formatter.format(value: cryptoValue)
    }

    func convertToFiat(_ cryptoValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
//        if cached?.crypto == cryptoValue {
//            return cached?.fiat
//        }

        guard let cryptoValue,
              let currencyId = tokenItem.currencyId,
              let fiatValue = BalanceConverter().convertToFiat(cryptoValue, currencyId: currencyId) else {
            return nil
        }

        formatter.update(maximumFractionDigits: 2)
        return formatter.format(value: fiatValue)
    }
}
