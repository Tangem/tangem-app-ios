//
//  SendTransactionSummaryDestinationHelper.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendTransactionSummaryDestinationHelper {
    // TODO: Remove optional
    func makeTransactionDescription(amount: Decimal?, fee: Decimal?, amountCurrencyId: String?, feeCurrencyId: String?) -> String? {
        guard
            let amount,
            let fee,
            let amountCurrencyId,
            let feeCurrencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        let amountInFiat = converter.convertToFiat(amount, currencyId: amountCurrencyId)
        let feeInFiat = converter.convertToFiat(fee, currencyId: feeCurrencyId)

        let totalInFiat: Decimal?
        if let amountInFiat, let feeInFiat {
            totalInFiat = amountInFiat + feeInFiat
        } else {
            totalInFiat = nil
        }

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )
        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat, formattingOptions: formattingOptions)
        let feeInFiatFormatted = formatter.formatFiatBalance(feeInFiat, formattingOptions: formattingOptions)

        return Localization.sendSummaryTransactionDescription(totalInFiatFormatted, feeInFiatFormatted)
    }
}
