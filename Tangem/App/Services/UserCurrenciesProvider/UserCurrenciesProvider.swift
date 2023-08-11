//
//  UserCurrenciesProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import Combine
import BlockchainSdk

struct UserCurrenciesProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let blockchain: Blockchain
    private let walletModelTokens: [Token]
    private let currencyMapper: CurrencyMapping

    init(blockchain: Blockchain, walletModelTokens: [Token], currencyMapper: CurrencyMapping) {
        self.blockchain = blockchain
        self.walletModelTokens = walletModelTokens
        self.currencyMapper = currencyMapper
    }
}

// MARK: - UserCurrenciesProviding

extension UserCurrenciesProvider: UserCurrenciesProviding {
    func getCurrencies(blockchain swappingBlockchain: SwappingBlockchain) async -> [Currency] {
        // get user tokens from API with filled in fields
        let tokens = await getTokens(
            blockchain: blockchain,
            ids: walletModelTokens.compactMap { $0.id }
        )

        var currencies: [Currency] = []
        if let coinCurrency = currencyMapper.mapToCurrency(blockchain: blockchain) {
            currencies.append(coinCurrency)
        }

        if walletModelTokens.isEmpty {
            return currencies
        }

        // Get user tokens from API with filled in fields
        // For checking exchangeable
        let filledTokens = await getTokens(
            blockchain: blockchain,
            ids: walletModelTokens.compactMap { $0.id }
        )

        currencies += filledTokens.compactMap { token in
            guard token.exchangeable == true else {
                return nil
            }

            return currencyMapper.mapToCurrency(token: token, blockchain: blockchain)
        }

        return currencies
    }
}

private extension UserCurrenciesProvider {
    func getTokens(blockchain: Blockchain, ids: [String]) async -> [Token] {
        let coins = try? await tangemApiService.loadCoins(
            requestModel: CoinsList.Request(supportedBlockchains: [blockchain], ids: ids)
        ).async()

        return coins?.compactMap { coin in
            coin.items.first(where: { $0.id == coin.id })?.token
        } ?? []
    }
}
