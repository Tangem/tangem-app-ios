//
//  KoinosSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 25.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosSendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension KoinosSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: Decimal) -> String? {
        let amountInFiat = tokenItem.id.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let feeFormatter = CommonFeeFormatter(balanceFormatter: formatter, balanceConverter: .init())

        return Localization.sendSummaryTransactionDescriptionNoFiatFee(
            formatter.formatFiatBalance(amountInFiat, formattingOptions: formattingOptions),
            feeFormatter.format(fee: fee, tokenItem: feeTokenItem)
        )
    }
}
