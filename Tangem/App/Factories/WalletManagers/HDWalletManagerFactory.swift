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

        guard let seedKey = seedKeys[curve], let derivedWalletKeys = derivedKeys[curve] else {
            throw AnyWalletManagerFactoryError.walletWithBlockchainCurveNotFound
        }

        let factory = WalletManagerFactoryProvider().factory
        let publicKey = try makePublicKey(seedKey: seedKey, for: blockchain, with: derivationPath, in: derivedWalletKeys)
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens(token.tokens)
        return walletManager
    }

    func makePublicKey(
        seedKey: Data,
        for blockchain: Blockchain,
        with derivationPath: DerivationPath,
        in derivedWalletKeys: [DerivationPath: ExtendedPublicKey]
    ) throws -> Wallet.PublicKey {
        guard let derivedKey = derivedWalletKeys[derivationPath] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let derivationKey = Wallet.PublicKey.DerivationKey(path: derivationPath, extendedPublicKey: derivedKey)

        // For extended cardano we should find a second extended public key
        guard case .cardano(let extended) = blockchain, extended else {
            return Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(derivationKey))
        }

        let extendedDerivationPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)
        guard let secondDerivedKey = derivedWalletKeys[extendedDerivationPath] else {
            throw AnyWalletManagerFactoryError.noDerivation
        }

        let secondDerivationKey = Wallet.PublicKey.DerivationKey(path: extendedDerivationPath, extendedPublicKey: secondDerivedKey)

        return Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .double(first: derivationKey, second: secondDerivationKey)
        )
    }
}
