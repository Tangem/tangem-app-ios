//
//  HDWalletManagerFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct HDWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> WalletManager {
        let seedKeys: [EllipticCurve: Data] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.derivedKeys
        }

        let blockchain = token.blockchainNetwork.blockchain
        let curve = blockchain.curve

        guard let derivationPath = token.blockchainNetwork.derivationPath else {
            throw AnyWalletManagerFactoryError.entryHasNotDerivationPath
        }

        guard let seedKey = seedKeys[curve],
              let derivedWalletKeys = derivedKeys[curve],
              let derivedKey = derivedWalletKeys[derivationPath] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let factory = WalletManagerFactoryProvider().factory
        let publicKey = Wallet.PublicKey(seedKey: seedKey, derivation: .init(path: derivationPath, derivedKey: derivedKey))
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(token.tokens)
        return walletManager
    }
    
    func makePublicKey(seedKey: Data, derivedWalletKeys: [DerivationPath : ExtendedPublicKey]) -> Wallet.PublicKey {
        
    }
}
