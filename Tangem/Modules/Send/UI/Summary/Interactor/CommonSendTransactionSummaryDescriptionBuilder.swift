//
//  CommonSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 25.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(transactionType: SendSummaryTransactionData) -> String? {
        guard case .send(let amount, let fee) = transactionType else {
            return nil
        }

        let amountInFiat = tokenItem.id.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }
        let feeInFiat = feeTokenItem.id.flatMap { BalanceConverter().convertToFiat(fee.amount.value, currencyId: $0) }

        var totalInFiat: Decimal? = nil

        if let amountInFiat, let feeInFiat {
            totalInFiat = amountInFiat + feeInFiat
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
