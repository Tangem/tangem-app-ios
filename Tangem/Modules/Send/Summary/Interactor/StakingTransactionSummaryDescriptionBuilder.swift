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

        let incomeFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 0,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .shortestFraction(roundingMode: .down)
        )

        let income = formatter.formatFiatBalance(amountFiat * apr, formattingOptions: incomeFormattingOptions)

        return Localization.stakingSummaryDescriptionText(amountInFiatFormatted, income)
    }
}
