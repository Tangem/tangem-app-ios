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
            guard let price = Decimal(string: value.price ?? ""),
                  let priceChange = Decimal(string: value.priceChange24h ?? "") else {
                return nil
            }

            return Quote(id: key, price: price, priceChange: priceChange)
        }
    }
}
