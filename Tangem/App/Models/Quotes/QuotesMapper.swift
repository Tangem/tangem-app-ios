//
//  QuotesMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct QuotesMapper {
    func mapToQuotes(_ response: QuotesDTO.Response) -> [Quote] {
        response.quotes.compactMap { key, value in
            guard let price = value.price else {
                return nil
            }

            let quote = Quote(
                id: key,
                price: price,
                priceChange: value.priceChange24h,
                priceChange7d: value.priceChange1w,
                priceChange30d: value.priceChange30d,
                prices24h: value.prices24h.map { Array($0.values) }
            )

            return quote
        }
    }
}
