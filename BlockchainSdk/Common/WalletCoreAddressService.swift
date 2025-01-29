//
//  WalletCoreAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct WalletCoreAddressService {
    private let coin: CoinType
    private let publicKeyType: PublicKeyType

    // MARK: - Init

    init(coin: CoinType, publicKeyType: PublicKeyType) {
        self.coin = coin
        self.publicKeyType = publicKeyType
    }
}

// MARK: - Convenience init

extension WalletCoreAddressService {
    init(coin: CoinType) {
        self.init(coin: coin, publicKeyType: coin.publicKeyType)
    }

    init(blockchain: Blockchain) {
        let coin = CoinType(blockchain)!
        self.init(coin: coin)
    }
}

// MARK: - AddressProvider

extension WalletCoreAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default:
            guard let walletCorePublicKey = PublicKey(tangemPublicKey: publicKey.blockchainKey, publicKeyType: publicKeyType) else {
                throw TWError.makeAddressFailed
            }

            let address = AnyAddress(publicKey: walletCorePublicKey, coin: coin).description
            let tmp = "addr1qxzah68yc5a5fyaz6pazzmuthvfwpnwcqlchxwgmskjukrw7n3ekrzf4fjhgz33gjnqcldugyqkgl6l0vylyazaryvush3qw95"
            let tmp1 = "addr1qy9eaqnmwjflxpsc8a2w8ezauxfqa9zske2xfsnyua2ld4stn6p8kayn7vrps065u0j9mcvjp629pdj5vnpxfe647mtq44hmyj"
            let tmp2 = "addr1q8calnxh03je9kxzx6gu9auw6mefz9x6kq6mwr5dnadjekm45ne6kl07fqtvvj99lrj74r570p5ra3c6ep0030428wgqj8deun"
            return PlainAddress(value: tmp2, publicKey: publicKey, type: addressType)
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
    func validate(_ address: String) -> Bool {
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
