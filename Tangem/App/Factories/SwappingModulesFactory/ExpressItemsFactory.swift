//
//  ExpressItemsFactory.swift
//  Tangem
//
//  Created by Andrew Son on 24/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

struct ExpressItemsFactory {
    func convertToTokenItem(_ asset: ExpressAsset, availableBlockchains: [String: Blockchain]) -> TokenItem? {
        guard let blockchain = availableBlockchains[asset.currency.network] else {
            return nil
        }

        if asset.currency.contractAddress == ExpressConstants.coinContractAddress {
            return .blockchain(blockchain)
        } else {
            let token = Token(
                name: asset.name,
                symbol: asset.symbol,
                contractAddress: asset.currency.contractAddress,
                decimalCount: asset.decimals,
                id: asset.token
            )
            return .token(token, blockchain)
        }
    }
}
