//
//  MarketsTokenDetailsMetricsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 10/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsMetricsViewModel {
    let records: [MarketsTokenDetailsMetricsView.RecordInfo]

    private let notationFormatter: DefaultAmountNotationFormatter
    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?

    private let formattingOptions = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .default(roundingMode: .plain, scale: 0)
    )

    private let metrics: MarketsTokenDetailsMetrics
    private let cryptoCurrencyCode: String

    private let cryptoFormatter: NumberFormatter

    init(
        metrics: MarketsTokenDetailsMetrics,
        notationFormatter: DefaultAmountNotationFormatter,
        cryptoCurrencyCode: String,
        infoRouter: MarketsTokenDetailsBottomSheetRouter?
    ) {
        self.metrics = metrics
        self.notationFormatter = notationFormatter
        self.cryptoCurrencyCode = cryptoCurrencyCode
        self.infoRouter = infoRouter

        let balanceFormatter = BalanceFormatter()
        cryptoFormatter = balanceFormatter.makeDefaultCryptoFormatter(forCurrencyCode: cryptoCurrencyCode, formattingOptions: formattingOptions)

        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let fiatFormatter = balanceFormatter.makeDefaultFiatFormatter(forCurrencyCode: AppSettings.shared.selectedCurrencyCode, formattingOptions: formattingOptions)

        let emptyValue = BalanceFormatter.defaultEmptyBalanceString

        func formatFiatValue(_ value: Decimal?) -> String {
            guard let value, value > 0 else {
                return emptyValue
            }

            return balanceFormatter.formatFiatBalance(value, formattingOptions: formattingOptions)
        }

        func formatCryptoValue(_ value: Decimal?) -> String {
            balanceFormatter.formatCryptoBalance(value, currencyCode: cryptoCurrencyCode)
        }

        var rating = emptyValue
        if let marketRating = metrics.marketRating, marketRating > 0 {
            rating = balanceFormatter.formatCryptoBalance(Decimal(marketRating), currencyCode: "", formattingOptions: formattingOptions)
        }

        var maxSupplyString = emptyValue
        if let maxSupply = metrics.maxSupply {
            if maxSupply == 0 {
                maxSupplyString = AppConstants.infinitySign
            } else {
                maxSupplyString = notationFormatter.format(maxSupply, notationFormatter: amountNotationFormatter, numberFormatter: cryptoFormatter, addingSignPrefix: false)
            }
        }
        records = [
            .init(type: .marketCapitalization, recordData: notationFormatter.format(metrics.marketCap, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .marketRating, recordData: rating),
            .init(type: .tradingVolume, recordData: notationFormatter.format(metrics.volume24H, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .fullyDilutedValuation, recordData: notationFormatter.format(metrics.fullyDilutedValuation, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .circulatingSupply, recordData: notationFormatter.format(metrics.circulatingSupply, notationFormatter: amountNotationFormatter, numberFormatter: cryptoFormatter, addingSignPrefix: false)),
            .init(type: .maxSupply, recordData: maxSupplyString),
        ]
    }

    func showInfoBottomSheet(for type: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: type.titleFull, message: type.infoDescription)
    }
}
