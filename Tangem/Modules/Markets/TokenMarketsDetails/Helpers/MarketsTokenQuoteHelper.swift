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
        if let dayChange = tokenQuote.priceChange24h {
            priceChangeDict[MarketsPriceIntervalType.day.rawValue] = dayChange
        }

        if let weekChange = tokenQuote.priceChange7d {
            priceChangeDict[MarketsPriceIntervalType.week.rawValue] = weekChange
        }

        if let monthChange = tokenQuote.priceChange30d {
            priceChangeDict[MarketsPriceIntervalType.month.rawValue] = monthChange
        }

        return priceChangeDict
    }
}
