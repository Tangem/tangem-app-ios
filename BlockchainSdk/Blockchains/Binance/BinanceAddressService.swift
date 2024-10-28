//
//  BinanceAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 15.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
struct BinanceAddressService {
    let testnet: Bool

    init(testnet: Bool) {
        self.testnet = testnet
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BinanceAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        if address.isEmpty {
            return false
        }

        guard let _ = try? Bech32().decode(address) else {
            return false
        }

        if !testnet, !address.starts(with: "bnb1") {
            return false
        }

        if testnet, !address.starts(with: "tbnb1") {
            return false
        }

        return true
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BinanceAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let keyHash = compressedKey.sha256Ripemd160

        if testnet {
            let address = Bech32().encode("tbnb", values: keyHash)
            return PlainAddress(value: address, publicKey: publicKey, type: addressType)
        } else {
            let address = Bech32().encode("bnb", values: keyHash)
            return PlainAddress(value: address, publicKey: publicKey, type: addressType)
        }
    }
}
