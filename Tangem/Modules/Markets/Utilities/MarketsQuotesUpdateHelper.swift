//
//  MarketsQuotesUpdateHelper.swift
//  Tangem
//
//  Created by Andrew Son on 14.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsQuotesUpdateHelper {
    /// Create`TokenQuote` list and updates it in `TokenQuotesRepository` for provided list of Markets entities
    /// - Parameters:
    ///   - marketsTokens: List of `MarketsTokenModel` items
    ///   - baseCurrencyCode: Currency selected in App. It can be fiat or crypto currency
    func updateQuotes(marketsTokens: [MarketsTokenModel], for baseCurrencyCode: String)

    /// Create single `TokenQuote`for provided `TokenMarketsDetailModel` and update data  in `TokenQuotesRepository`
    /// - Parameters:
    ///   - marketToken: Details about single Token represented in `TokenMarketsDetailsModel`
    ///   - baseCurrencyCode: Currency selected in App. It can be fiat or crypto currency
    func updateQuote(marketToken: MarketsTokenDetailsModel, for baseCurrencyCode: String)
}

struct CommonMarketsQuotesUpdateHelper: MarketsQuotesUpdateHelper {
    @Injected(\.quotesRepositoryUpdater) private var quotesRepositoryUpdater: TokenQuotesRepositoryUpdater

    func updateQuotes(marketsTokens: [MarketsTokenModel], for baseCurrencyCode: String) {
        let quotes: [TokenQuote] = marketsTokens.compactMap {
            guard let price = $0.currentPrice else {
                return nil
            }

            return TokenQuote(
                currencyId: $0.id,
                price: price,
                priceChange24h: $0.priceChangePercentage[MarketsPriceIntervalType.day.marketsListId],
                priceChange7d: $0.priceChangePercentage[MarketsPriceIntervalType.week.marketsListId],
                priceChange30d: $0.priceChangePercentage[MarketsPriceIntervalType.month.marketsListId],
                currencyCode: baseCurrencyCode
            )
        }

        quotesRepositoryUpdater.saveQuotes(quotes)
    }

    func updateQuote(marketToken: MarketsTokenDetailsModel, for baseCurrencyCode: String) {
        let quote = TokenQuote(
            currencyId: marketToken.id,
            price: marketToken.currentPrice,
            priceChange24h: marketToken.priceChangePercentage[MarketsPriceIntervalType.day.rawValue],
            priceChange7d: marketToken.priceChangePercentage[MarketsPriceIntervalType.week.rawValue],
            priceChange30d: marketToken.priceChangePercentage[MarketsPriceIntervalType.month.rawValue],
            currencyCode: baseCurrencyCode
        )

        quotesRepositoryUpdater.saveQuote(quote)
    }
}
