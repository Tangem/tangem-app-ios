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
    private let balanceFormatter = BalanceFormatter()

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension StakingTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(transactionType: SendSummaryTransactionData) -> String? {
        guard case .staking(let amount, let schedule) = transactionType,
              let amountFiat = amount.fiat else {
            return nil
        }

        let amountFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let amountInFiatFormatted = balanceFormatter.formatFiatBalance(amountFiat, formattingOptions: amountFormattingOptions)

        let scheduleFormatted = schedule.formatted().lowercased()
        return Localization.stakingSummaryDescriptionText(amountInFiatFormatted, scheduleFormatted)
    }
}
