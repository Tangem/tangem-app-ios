//
//  WalletCoreAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

public struct WalletCoreAddressService {
    private let coin: CoinType
    private let publicKeyType: PublicKeyType

    // MARK: - Init

    public init(coin: CoinType, publicKeyType: PublicKeyType) {
        guard coin != .ton else {
            fatalError("Use TonAddress service instead")
        }
        self.coin = coin
        self.publicKeyType = publicKeyType
    }
}

// MARK: - Convenience init

extension WalletCoreAddressService {
    public init(coin: CoinType) {
        self.init(coin: coin, publicKeyType: coin.publicKeyType)
    }

    public init(blockchain: Blockchain) {
        let coin = CoinType(blockchain)!
        self.init(coin: coin)
    }
}

// MARK: - AddressProvider

extension WalletCoreAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default:
            guard let walletCorePublicKey = PublicKey(tangemPublicKey: publicKey.blockchainKey, publicKeyType: publicKeyType) else {
                throw TWError.makeAddressFailed
            }

            let address = AnyAddress(publicKey: walletCorePublicKey, coin: coin).description
            return PlainAddress(value: address, publicKey: publicKey, type: addressType)
        case .legacy:
            if coin == .cardano {
                let address = try makeByronAddress(publicKey: publicKey)
                return PlainAddress(value: address, publicKey: publicKey, type: addressType)
            }
            
            fatalError("WalletCoreAddressService don't support legacy address for \(coin)")
        }
    }
}

// MARK: - AddressValidator

extension WalletCoreAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        return AnyAddress(string: address, coin: coin) != nil
    }
}

private extension WalletCoreAddressService {
    func makeByronAddress(publicKey: Wallet.PublicKey) throws -> String {
        guard let publicKey = PublicKey(data: publicKey.blockchainKey, type: .ed25519Cardano) else {
            throw TWError.makeAddressFailed
        }
        
        let byronAddress = Cardano.getByronAddress(publicKey: publicKey)
        return byronAddress
    }
}

extension WalletCoreAddressService {
    enum TWError: Error {
        case makeAddressFailed
    }
}
