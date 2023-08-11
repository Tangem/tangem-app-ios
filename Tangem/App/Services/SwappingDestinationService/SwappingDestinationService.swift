//
//  SwappingDestinationService.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

struct SwappingDestinationService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let blockchain: Blockchain
    private let mapper: CurrencyMapping
    private let walletModelTokens: [Token]

    init(blockchain: Blockchain, mapper: CurrencyMapping, walletModelTokens: [Token]) {
        self.blockchain = blockchain
        self.mapper = mapper
        self.walletModelTokens = walletModelTokens
    }
}

// MARK: - SwappingDestinationServicing

extension SwappingDestinationService: SwappingDestinationServicing {
    func getDestination(source: Currency) async throws -> Currency {
        switch source.currencyType {
        case .token:
            if let currency = mapper.mapToCurrency(blockchain: blockchain) {
                return currency
            }

        case .coin:
            var preferredToken: Token?

            for preferred in PreferredTokenSymbol.allCases {
                if let token = walletModelTokens.first(where: { $0.symbol == preferred.rawValue }) {
                    preferredToken = token
                    break
                }
            }

            if let preferredToken,
               let currency = mapper.mapToCurrency(token: preferredToken, blockchain: blockchain) {
                return currency
            }

            return try await loadPreferredCurrency(networkId: blockchain.networkId)
        }

        throw CommonError.noData
    }
}

private extension SwappingDestinationService {
    func loadPreferredCurrency(networkId: String) async throws -> Currency {
        for preferred in PreferredTokenSymbol.allCases {
            if let currency = try? await loadPreferredCurrencyFromAPI(tokenSymbol: preferred.rawValue) {
                return currency
            }
        }

        return try await loadPreferredCurrencyFromAPI()
    }

    func loadPreferredCurrencyFromAPI(tokenSymbol: String? = nil) async throws -> Currency {
        let model = CoinsList.Request(
            supportedBlockchains: [blockchain],
            searchText: tokenSymbol,
            exchangeable: true
        )

        let coinModels = try await tangemApiService.loadCoins(requestModel: model).async()
        let coinModel: CoinModel?

        /// If we are founding special token by name
        if let tokenSymbol = tokenSymbol {
            coinModel = coinModels.first(where: { $0.symbol == tokenSymbol })
        } else {
            coinModel = coinModels.first
        }

        if let coinModel, let currency = mapper.mapToCurrency(coinModel: coinModel) {
            return currency
        }

        throw CommonError.noData
    }
}

extension SwappingDestinationService {
    enum PreferredTokenSymbol: String, CaseIterable {
        case usdt = "USDT"
        case usdc = "USDC"
    }
}
