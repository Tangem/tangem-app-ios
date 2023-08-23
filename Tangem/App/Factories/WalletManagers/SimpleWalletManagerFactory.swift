//
//  SimpleWalletManagerFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SimpleWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> WalletManager {
        let blockchain = token.blockchainNetwork.blockchain

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(token.tokens)
        return walletManager
    }
}
