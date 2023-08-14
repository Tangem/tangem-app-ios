//
//  SupportedSwappingBlockchain.swift
//  Tangem
//
//  Created by Sergey Balashov on 02.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import BlockchainSdk

struct SwappingAvailableUtils {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let supportedBlockchains: [SwappingBlockchain] = [
        .ethereum,
        .bsc,
        .polygon,
        .optimism,
        .arbitrum,
        .gnosis,
        .avalanche,
        .fantom,
    ]

    func canSwap(amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        // Checking that toggle is on
        guard FeatureProvider.isAvailable(.exchange) else {
            return false
        }

        guard let blockchain = makeSwappingBlockchain(from: blockchain) else {
            return false
        }

        switch amountType {
        case .coin:
            return supportedBlockchains.contains(blockchain)
        case .token(let token):
            // If exchangeable == nil then swap is available for old users
            return !token.isCustom && (token.exchangeable ?? true)
        default:
            return false
        }
    }

    func canSwapPublisher(amountType: Amount.AmountType, blockchain: Blockchain) -> AnyPublisher<Bool, Error> {
        guard
            FeatureProvider.isAvailable(.exchange),
            let swapBlockchain = makeSwappingBlockchain(from: blockchain),
            supportedBlockchains.contains(swapBlockchain)
        else {
            return .justWithError(output: false)
        }

        switch amountType {
        case .coin:
            return .justWithError(output: true)
        case .token(let token):
            // For a custom token id == nil
            guard let currencyId = token.id, !token.isCustom else {
                return .justWithError(output: false)
            }

            let networkId = swapBlockchain.networkId
            return tangemApiService
                .loadCoins(requestModel: .init(supportedBlockchains: [blockchain], ids: [currencyId]))
                .map { models in
                    let coin = models.first(where: { $0.id == currencyId })
                    let tokenItem = coin?.items.first(where: { $0.id == currencyId })

                    if case .token(let token, _) = tokenItem {
                        // If exchangeable == nil then swap is available for old users
                        return token.exchangeable ?? true
                    }

                    return false
                }
                .eraseToAnyPublisher()
        default:
            return .justWithError(output: false)
        }
    }

    private func makeSwappingBlockchain(from blockchain: Blockchain) -> SwappingBlockchain? {
        let networkId = blockchain.networkId
        return SwappingBlockchain(networkId: networkId)
    }
}
