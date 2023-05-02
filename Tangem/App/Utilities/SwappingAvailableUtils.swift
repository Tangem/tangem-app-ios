//
//  SupportedSwappingBlockchain.swift
//  Tangem
//
//  Created by Sergey Balashov on 02.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk

struct SwappingAvailableUtils {
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

        let networkId = blockchain.networkId
        guard let blockchain = SwappingBlockchain(networkId: networkId) else {
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
}
