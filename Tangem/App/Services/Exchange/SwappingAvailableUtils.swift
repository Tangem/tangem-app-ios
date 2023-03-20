//
//  SupportedExchangeBlockchain.swift
//  Tangem
//
//  Created by Sergey Balashov on 02.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

struct SwappingAvailableUtils {
    private let supportedBlockchains: [ExchangeBlockchain] = [
        .ethereum,
        .bsc,
        .polygon,
        // .optimism,
        .arbitrum,
        .gnosis,
        .avalanche,
        .fantom,
    ]

    func canSwap(blockchainNetworkId: String) -> Bool {
        // Checking that toggle is on
        guard FeatureProvider.isAvailable(.exchange) else {
            return false
        }

        guard let blockchain = ExchangeBlockchain(networkId: blockchainNetworkId) else {
            return false
        }

        return supportedBlockchains.contains(blockchain)
    }
}
