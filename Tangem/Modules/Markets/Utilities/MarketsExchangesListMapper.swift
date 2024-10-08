//
//  MarketsExchangesListMapper.swift
//  Tangem
//
//  Created by Andrew Son on 03.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsExchangesListMapper {
    func mapListToItemInfo(_ list: [MarketsDTO.ExchangesListItemInfo]) -> [MarketsTokenDetailsExchangeItemInfo] {
        let notationFormatter = DefaultAmountNotationFormatter()
        let amountSuffixNotationFormatter: AmountNotationSuffixFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: 0)
        )
        let fiatFormatter = BalanceFormatter().makeDefaultFiatFormatter(
            forCurrencyCode: AppConstants.usdCurrencyCode,
            formattingOptions: formattingOptions
        )
        let iconURLBuilder = IconURLBuilder()

        return list.map {
            let iconURL: URL?
            if let link = $0.image {
                iconURL = URL(string: link)
            } else {
                iconURL = iconURLBuilder.exchangesIconURL(exchangeId: $0.exchangeId)
            }

            let formattedVolumeUSD = notationFormatter.format(
                $0.volumeUsd,
                notationFormatter: amountSuffixNotationFormatter,
                numberFormatter: fiatFormatter,
                addingSignPrefix: false
            )
            return MarketsTokenDetailsExchangeItemInfo(
                id: $0.exchangeId,
                name: $0.name,
                trustScore: $0.trustScore ?? .risky,
                exchangeType: $0.centralized ? .cex : .dex,
                iconURL: iconURL,
                formattedVolume: formattedVolumeUSD
            )
        }
    }
}
