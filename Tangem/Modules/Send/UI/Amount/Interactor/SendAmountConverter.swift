//
//  SendAmountConverter.swift
//  Tangem
//
//  Created by Sergey Balashov on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmountConverter {
    func convertToCrypto(_ fiatValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
        guard let fiatValue,
              let currencyId = tokenItem.currencyId,
              let cryptoValue = BalanceConverter().convertFromFiat(fiatValue, currencyId: currencyId) else {
            return nil
        }

        let formatter = DecimalNumberFormatter(maximumFractionDigits: tokenItem.decimalCount)
        return formatter.format(value: cryptoValue)
    }

    func convertToFiat(_ cryptoValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
        guard let cryptoValue,
              let currencyId = tokenItem.currencyId,
              let fiatValue = BalanceConverter().convertToFiat(cryptoValue, currencyId: currencyId) else {
            return nil
        }

        let formatter = DecimalNumberFormatter(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)
        return formatter.format(value: fiatValue)
    }
}
