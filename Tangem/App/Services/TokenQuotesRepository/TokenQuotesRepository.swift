//
//  TokenQuotesRepository.swift
//  Tangem
//
//  Created by Andrew Son on 03/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

typealias Quotes = [String: TokenQuote]

typealias TokenQuotesRepository = TokenQuotesDataProvider & TokenQuotesRepositoryUpdater

protocol TokenQuotesDataProvider: AnyObject {
    var quotes: Quotes { get }
    var quotesPublisher: AnyPublisher<Quotes, Never> { get }

    func quote(for currencyId: String) async throws -> TokenQuote
}

extension TokenQuotesDataProvider {
    func quote(for id: String?) -> TokenQuote? {
        guard let id else {
            return nil
        }

        return quotes[id]
    }

    func quote(for item: TokenItem) -> TokenQuote? {
        return quote(for: item.currencyId)
    }
}

protocol TokenQuotesRepositoryUpdater: AnyObject {
    /// Use it just for load and save quotes in the cache
    /// For get updates make a subscribe to quotesPublisher
    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never>

    func saveQuotes(_ quotes: [TokenQuote])
    func saveQuote(_ quote: TokenQuote)
}

extension TokenQuotesRepositoryUpdater {
    func loadQuotes(currencyIds: [String]) async {
        try? await loadQuotes(currencyIds: currencyIds).async()
    }

    func saveQuote(_ quote: TokenQuote) {
        saveQuotes([quote])
    }
}

private struct TokenQuotesRepositoryKey: InjectionKey {
    static var currentValue: TokenQuotesRepository = CommonTokenQuotesRepository()
}

extension InjectedValues {
    var quotesDataProvider: TokenQuotesDataProvider { Self[TokenQuotesRepositoryKey.self] }

    var quotesRepositoryUpdater: TokenQuotesRepositoryUpdater { Self[TokenQuotesRepositoryKey.self] }

    var quotesRepository: TokenQuotesRepository {
        get { Self[TokenQuotesRepositoryKey.self] }
        set { Self[TokenQuotesRepositoryKey.self] = newValue }
    }
}
