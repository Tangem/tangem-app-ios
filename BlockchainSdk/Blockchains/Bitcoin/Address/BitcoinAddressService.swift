//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

@available(iOS 13.0, *)
struct BitcoinAddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService

    init(networkParams: INetwork) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default:
            let bech32AddressString = try bech32.makeAddress(from: publicKey.blockchainKey).value
            return PlainAddress(value: bech32AddressString, publicKey: publicKey, type: addressType)
        case .legacy:
            let legacyAddressString = try legacy.makeAddress(from: publicKey.blockchainKey).value
            return PlainAddress(value: legacyAddressString, publicKey: publicKey, type: addressType)
        }
    }
}

// MARK: - BitcoinScriptAddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: BitcoinScriptAddressesProvider {
    func makeAddresses(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> [BitcoinScriptAddress] {
        let compressedKeys = try [publicKey.blockchainKey, pairPublicKey].map {
            let key = try Secp256k1Key(with: $0)
            return try key.compress()
        }

        let script = try BitcoinScriptBuilder().makeMultisig(publicKeys: compressedKeys, signaturesRequired: 1)
        let legacyAddressString = try legacy.makeScriptAddress(from: script.data.sha256Ripemd160)
        let scriptAddress = BitcoinScriptAddress(script: script, value: legacyAddressString, publicKey: publicKey, type: .legacy)

        let bech32AddressString = try bech32.makeScriptAddress(from: script.data.sha256())
        let bech32Address = BitcoinScriptAddress(script: script, value: bech32AddressString, publicKey: publicKey, type: .default)

        return [bech32Address, scriptAddress]
    }
}
