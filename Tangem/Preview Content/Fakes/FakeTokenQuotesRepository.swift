//
//  FakeTokenQuotesRepository.swift
//  Tangem
//
//  Created by Andrew Son on 25/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeTokenQuotesRepository: TokenQuotesRepository, TokenQuotesRepositoryUpdater {
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
                price: Decimal(floatLiteral: Double.random(in: 1 ... 50000)),
                priceChange24h: Decimal(floatLiteral: Double.random(in: -10 ... 10)),
                priceChange7d: Decimal(floatLiteral: Double.random(in: -100 ... 100)),
                priceChange30d: Decimal(floatLiteral: Double.random(in: -1000 ... 1000)),
                currencyCode: AppSettings.shared.selectedCurrencyCode
            )

            return (id, quote)
        }

        currentQuotes.send(Dictionary(uniqueKeysWithValues: zipped))
    }

    func quote(for item: TokenItem) -> TokenQuote? {
        TokenQuote(
            currencyId: item.currencyId!,
            price: 1,
            priceChange24h: 3.3,
            priceChange7d: 43.3,
            priceChange30d: 93.3,
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )
    }

    func quote(for currencyId: String) async throws -> TokenQuote {
        await TokenQuote(
            currencyId: currencyId,
            price: 1,
            priceChange24h: 3.3,
            priceChange7d: 43.3,
            priceChange30d: 93.3,
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )
    }

    func loadQuotes(currencyIds: [String]) -> AnyPublisher<[String: Decimal], Never> {
        Just([:]).eraseToAnyPublisher()
    }

    func loadPrice(currencyCode: String, currencyId: String) -> AnyPublisher<Decimal, any Error> {
        Just(1.2345).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func saveQuotes(_ quotes: [TokenQuote]) {
        var current = currentQuotes.value

        quotes.forEach { quote in
            current[quote.currencyId] = quote
        }

        currentQuotes.send(current)
    }

    func saveQuotes(_ quotes: [Quote], currencyCode: String) {
        let quotes = quotes.map { quote in
            TokenQuote(
                currencyId: quote.id,
                price: quote.price,
                priceChange24h: quote.priceChange,
                priceChange7d: quote.priceChange7d,
                priceChange30d: quote.priceChange30d,
                currencyCode: currencyCode
            )
        }

        saveQuotes(quotes)
    }
}
