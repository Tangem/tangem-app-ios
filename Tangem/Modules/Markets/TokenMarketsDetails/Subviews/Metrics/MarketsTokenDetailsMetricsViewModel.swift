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

    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?

    init(metrics: MarketsTokenDetailsMetrics, infoRouter: MarketsTokenDetailsBottomSheetRouter?) {
        self.infoRouter = infoRouter

        let formatter = BalanceFormatter()
        let options = BalanceFormattingOptions(minFractionDigits: 0, maxFractionDigits: 0, formatEpsilonAsLowestRepresentableValue: false, roundingType: .default(roundingMode: .plain, scale: 0))
        let emptyValue = AppConstants.dashSign

        func formatFiatValue(_ value: Decimal?) -> String {
            guard let value, value > 0 else {
                return emptyValue
            }

            return formatter.formatFiatBalance(value, formattingOptions: options)
        }

        var rating = emptyValue
        if let marketRating = metrics.marketRating, marketRating > 0 {
            rating = formatter.formatCryptoBalance(Decimal(marketRating), currencyCode: "", formattingOptions: options)
        }
        records = [
            .init(type: .marketCapitalization, recordData: formatFiatValue(metrics.marketCap)),
            .init(type: .marketRating, recordData: rating),
            .init(type: .tradingVolume, recordData: formatFiatValue(metrics.volume24H)),
            .init(type: .fullyDilutedValuation, recordData: formatFiatValue(metrics.fullyDilutedValuation)),
            .init(type: .circulatingSupply, recordData: formatFiatValue(metrics.circulatingSupply)),
            .init(type: .totalSupply, recordData: formatFiatValue(metrics.totalSupply)),
        ]
    }

    func showInfoBottomSheet(for type: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: type.title, message: type.infoDescription)
    }
}
