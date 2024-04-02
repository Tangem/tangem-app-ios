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

protocol TokenQuotesRepository: AnyObject {
    var quotes: Quotes { get }
    var quotesPublisher: AnyPublisher<Quotes, Never> { get }

    func quote(for currencyId: String) async throws -> TokenQuote
    /// Use it just for load and save quotes in the cache
    /// For get updates make a subscribe to quotesPublisher
    func loadQuotes(currencyIds: [String]) -> AnyPublisher<Void, Never>
}

extension TokenQuotesRepository {
    func loadQuotes(currencyIds: [String]) async {
        try? await loadQuotes(currencyIds: currencyIds).async()
    }

    func quote(for item: TokenItem) -> TokenQuote? {
        guard let id = item.currencyId else {
            return nil
        }

        return quotes[id]
    }
}

private struct TokenQuotesRepositoryKey: InjectionKey {
    static var currentValue: TokenQuotesRepository = CommonTokenQuotesRepository()
}

extension InjectedValues {
    var quotesRepository: TokenQuotesRepository {
        get { Self[TokenQuotesRepositoryKey.self] }
        set { Self[TokenQuotesRepositoryKey.self] = newValue }
    }
}
