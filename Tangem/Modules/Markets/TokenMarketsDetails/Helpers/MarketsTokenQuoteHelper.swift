//
//  MarketsTokenQuoteHelper.swift
//  Tangem
//
//  Created by Andrew Son on 14.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenQuoteHelper {
    func makePriceChangeIntervalsDictionary(from tokenQuote: TokenQuote?) -> [String: Decimal]? {
        guard let tokenQuote else {
            return nil
        }

        var priceChangeDict = [String: Decimal]()
        priceChangeDict[MarketsPriceIntervalType.day.rawValue] = tokenQuote.priceChange24h
        priceChangeDict[MarketsPriceIntervalType.week.rawValue] = tokenQuote.priceChange7d
        priceChangeDict[MarketsPriceIntervalType.month.rawValue] = tokenQuote.priceChange30d

        return priceChangeDict
    }
}
