//
//  GenericWalletManagerFactory.swift
//  Tangem
//
//  Created by skibinalexander on 16.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GenericWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet], apiList: APIList) throws -> WalletManager {
        switch token.blockchainNetwork.blockchain {
        case .chia:
            return try SimpleWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
        case .cardano(let extended):
            if extended {
                return try CardanoWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
            } else {
                return try HDWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
            }
        default:
            return try HDWalletManagerFactory().makeWalletManager(for: token, keys: keys, apiList: apiList)
        }
    }
}
