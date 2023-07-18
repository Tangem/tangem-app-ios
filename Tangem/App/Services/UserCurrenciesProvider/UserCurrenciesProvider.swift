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

    private let walletModel: WalletModel
    private let currencyMapper: CurrencyMapping

    init(walletModel: WalletModel, currencyMapper: CurrencyMapping) {
        self.walletModel = walletModel
        self.currencyMapper = currencyMapper
    }
}

// MARK: - UserCurrenciesProviding

extension UserCurrenciesProvider: UserCurrenciesProviding {
    func getCurrencies(blockchain swappingBlockchain: SwappingBlockchain) async -> [Currency] {
        let blockchain = walletModel.blockchainNetwork.blockchain

        guard blockchain.networkId == swappingBlockchain.networkId else {
            assertionFailure("incorrect blockchain in WalletModel")
            return []
        }

        var currencies: [Currency] = []
        if let coinCurrency = currencyMapper.mapToCurrency(blockchain: blockchain) {
            currencies.append(coinCurrency)
        }

        let userTokens = walletModel.getTokens()
        if userTokens.isEmpty {
            return currencies
        }

        // Get user tokens from API with filled in fields
        // For checking exchangeable
        let filledTokens = await getTokens(
            networkId: swappingBlockchain.networkId,
            ids: userTokens.compactMap { $0.id }
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
    func getTokens(networkId: String, ids: [String]) async -> [Token] {
        let coins = try? await tangemApiService.loadCoins(
            requestModel: CoinsListRequestModel(networkIds: [networkId], ids: ids)
        ).async()

        return coins?.compactMap { coin in
            coin.items.first(where: { $0.id == coin.id })?.token
        } ?? []
    }
}
