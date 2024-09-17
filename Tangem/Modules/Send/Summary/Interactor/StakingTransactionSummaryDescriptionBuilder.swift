//
//  StakingTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakingTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension StakingTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(transactionType: SendSummaryTransactionData) -> String? {
        guard case .staking(let amount, _, let apr) = transactionType,
              let amountFiat = amount.fiat else {
            return nil
        }

        let amountFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let amountInFiatFormatted = formatter.formatFiatBalance(amountFiat, formattingOptions: amountFormattingOptions)

        let amountPerYear = amountFiat * apr

        let useRoundedValues = amountPerYear >= 1

        let fractionDigits = useRoundedValues ? 0 : 2

        let incomeFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: fractionDigits,
            maxFractionDigits: fractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .shortestFraction(roundingMode: .up)
        )

        var income = formatter.formatFiatBalance(amountPerYear, formattingOptions: incomeFormattingOptions)
        if useRoundedValues {
            income = "~" + income
        }

        return Localization.stakingSummaryDescriptionText(amountInFiatFormatted, income)
    }
}
