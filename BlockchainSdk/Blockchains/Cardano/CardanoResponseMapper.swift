//
//  CardanoResponseMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardanoResponseMapper {
    func mapToCardanoAddressResponse(
        tokens: [Token],
        unspentOutputs: [CardanoUnspentOutput],
        recentTransactionsHashes: [String]
    ) -> CardanoAddressResponse {
        let coinBalance: UInt64 = unspentOutputs.reduce(0) { $0 + $1.amount }

        let tokenBalances: [Token: UInt64] = tokens.reduce(into: [:]) { tokenBalances, token in
            let assetFilter = CardanoAssetFilter(contractAddress: token.contractAddress)
            // Collecting of all output balance
            tokenBalances[token, default: 0] += unspentOutputs.reduce(0) { result, output in
                // Sum with each asset in output amount
                result + output.assets.reduce(into: 0) { result, asset in
                    if assetFilter.isEqualToAssetWith(policyId: asset.policyID, assetNameHex: asset.assetNameHex) {
                        result += asset.amount
                    }
                }
            }
        }

        return CardanoAddressResponse(
            balance: coinBalance,
            tokenBalances: tokenBalances,
            recentTransactionsHashes: recentTransactionsHashes,
            unspentOutputs: unspentOutputs
        )
    }
}
