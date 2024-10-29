//
//  BIP39ServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore
@testable import BlockchainSdk

final class KeysServiceManagerUtility {
    // MARK: - Properties

    private let seed: Data
    private let hdWallet: HDWallet

    // MARK: - Init

    public init(mnemonic: String, passphrase: String = "") throws {
        seed = try Mnemonic(with: mnemonic).generateSeed(with: passphrase)
        hdWallet = HDWallet(mnemonic: mnemonic, passphrase: passphrase)!
    }

    // MARK: - Implementation

    func getBIP32Seed() throws -> Data {
        return seed
    }

    func getMasterKeyFromTrustWallet(for blockchain: BlockchainSdk.Blockchain) throws -> PrivateKey {
        try hdWallet.getMasterKey(curve: .init(blockchain: blockchain))
    }

    func getMasterKeyFromBIP32(with seed: Data, for blockchain: BlockchainSdk.Blockchain) throws -> ExtendedPrivateKey {
        try BIP32().makeMasterKey(from: seed, curve: blockchain.curve)
    }

    /// Basic validation and store local keys wallet
    func getPublicKeyFromTrustWallet(
        blockchain: BlockchainSdk.Blockchain,
        privateKey: PrivateKey
    ) throws -> PublicKey {
        return try privateKey.getPublicKeyByType(pubkeyType: .init(blockchain)).compressed
    }

    /// Basic validation and store local keys wallet
    func getPublicKeyFromTangemSdk(
        blockchain: BlockchainSdk.Blockchain,
        privateKey: ExtendedPrivateKey
    ) throws -> ExtendedPublicKey {
        do {
            return try privateKey.makePublicKey(for: blockchain.curve)
        } catch {
            throw NSError(domain: "__INVALID_EXECUTE_SDK_KEY__ \(error.localizedDescription) BLOCKCHAIN \(blockchain.currencySymbol)", code: -1)
        }
    }

    /// Basic validation and store local keys wallet
    func getPublicKeyFromTrustWallet(
        blockchain: BlockchainSdk.Blockchain,
        derivation: String
    ) throws -> PublicKey {
        if let coin = CoinType(blockchain) {
            return try hdWallet.getKey(coin: coin, derivationPath: derivation).getPublicKeyByType(pubkeyType: .init(blockchain))
        } else {
            throw NSError(domain: "__INVALID_EXECUTE_TW_KEY__ BLOCKCHAIN \(blockchain.currencySymbol)", code: -1)
        }
    }
}
