//
//  WalletCoreBitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 04.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct BitcoinWalletCoreAddressAdapter {
    private let coin: CoinType
    private let publicKeyType: PublicKeyType

    // MARK: - Init

    init(coin: CoinType, publicKeyType: PublicKeyType) {
        /*
         This validation is intended to filter only those blockchains that we dare to adapt
         A similar implementation was made at the WalletCoreAddressService through force unrap
         */
        guard Constants.supportedBitcoinCoinType.contains(coin) else {
            fatalError("This coin \(coin) does not supported bitcoin type for adapter address")
        }
        
        self.coin = coin
        self.publicKeyType = publicKeyType
    }
}

// MARK: - Convenience init

extension BitcoinWalletCoreAddressAdapter {
    init(coin: CoinType) {
        self.init(coin: coin, publicKeyType: coin.publicKeyType)
    }

    init(_ blockchain: Blockchain) {
        let coin = CoinType(blockchain)!
        self.init(coin: coin)
    }
}

// MARK: - AddressProvider

extension BitcoinWalletCoreAddressAdapter {
    func makeAddress(for publicKey: Wallet.PublicKey, by prefix: BitcoinPrefix) throws -> BitcoinAddress {
        let coinPrefix = prefix.value(for: coin)
        
        guard
            let walletCorePublicKey = PublicKey(tangemPublicKey: publicKey.blockchainKey, publicKeyType: publicKeyType),
            let address = BitcoinAddress(publicKey: walletCorePublicKey, prefix: coinPrefix)
        else {
            throw Error.makeAddressFailed
        }
        
        return address
    }
}

// MARK: - AddressValidator

extension BitcoinWalletCoreAddressAdapter: AddressValidator {
    public func validate(_ address: String) -> Bool {
        BitcoinAddress.isValidString(string: address)
    }
    
    /// Use specify method use a method specifically for the prefix
    /// - Parameters:
    ///   - prefix: Bitcon TW prefix
    func validateSpecify(prefix: BitcoinPrefix, for address: String) -> Bool {
        guard let address = BitcoinAddress(string: address), address.prefix == prefix.value(for: coin) else {
            return false
        }
        
        return true
    }
}

extension BitcoinWalletCoreAddressAdapter {
    enum BitcoinPrefix {
        case p2pkh
        case p2sh
        
        func value(for bitcoinCoin: CoinType) -> UInt8 {
            switch self {
            case .p2pkh:
                bitcoinCoin.p2pkhPrefix
            case .p2sh:
                bitcoinCoin.p2shPrefix
            }
        }
    }
    
    enum Error: Swift.Error {
        case makeAddressFailed
    }
    
    enum Constants {
        static var supportedBitcoinCoinType: [CoinType] {
            [.bitcoin, .bitcoinCash, .dash, .litecoin, .dogecoin]
        }
    }
}
