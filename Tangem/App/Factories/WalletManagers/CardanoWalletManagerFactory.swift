//
//  CardanoWalletManagerFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CardanoWalletManagerFactory: AnyWalletManagerFactory {
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

        guard let seedKey = seedKeys[curve], let derivedWalletKeys = derivedKeys[curve] else {
            throw AnyWalletManagerFactoryError.walletWithBlockchainCurveNotFound
        }

        let extendedDerivationPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)

        guard let derivedKey = derivedWalletKeys[derivationPath],
              let secondDerivedKey = derivedWalletKeys[extendedDerivationPath] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let derivationKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let secondDerivationKey = Wallet.PublicKey.HDKey(path: extendedDerivationPath, extendedPublicKey: secondDerivedKey)

        let factory = WalletManagerFactoryProvider().factory
        let publicKey = Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .double(first: derivationKey, second: secondDerivationKey)
        )

        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(token.tokens)
        return walletManager
    }
}
