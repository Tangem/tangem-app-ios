//
//  FakeTokenQuotesRepository.swift
//  Tangem
//
//  Created by Andrew Son on 25/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeTokenQuotesRepository: TokenQuotesRepository {
    var quotes: Quotes {
        currentQuotes.value
    }

    var quotesPublisher: AnyPublisher<Quotes, Never> {
        currentQuotes.eraseToAnyPublisher()
    }

    private let currentQuotes = CurrentValueSubject<Quotes, Never>([:])

    init(walletManagers: [FakeWalletManager]) {
        let walletModels = walletManagers.flatMap { $0.walletModels }
        var filter = Set<String>()
        let zipped: [(String, TokenQuote)] = walletModels.compactMap {
            let id = $0.tokenItem.currencyId ?? ""
            if filter.contains(id) {
                return nil
            }

            filter.insert(id)
            let quote = TokenQuote(
                currencyId: id,
                change: Decimal(floatLiteral: Double.random(in: -10 ... 10)),
                price: Decimal(floatLiteral: Double.random(in: 1 ... 50000)),
                prices24h: [
                    Double.random(in: -10 ... 10),
                    Double.random(in: -10 ... 10),
                ],
                currencyCode: AppSettings.shared.selectedCurrencyCode
            )

            return (id, quote)
        }

        currentQuotes.send(Dictionary(uniqueKeysWithValues: zipped))
    }

    func quote(for item: TokenItem) -> TokenQuote? {
        TokenQuote(currencyId: item.currencyId!, change: 3.3, price: 1, prices24h: [1, 2, 3], currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func quote(for currencyId: String) async throws -> TokenQuote {
        await TokenQuote(currencyId: currencyId, change: 3.3, price: 1, prices24h: [1, 2, 3], currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never> {
        quotesPublisher.mapToVoid().eraseToAnyPublisher()
    }
}
