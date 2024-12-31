//
//  Fact0rnAddressService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import TangemSdk

// TODO: [Fact0rn] Implement AddressService
// https://tangem.atlassian.net/browse/IOS-8756
struct Fact0rnAddressService {
    let addressConverter: SegWitBech32AddressConverter

    init() {
        let networkParams = Fact0rnMainNetworkParams()
        let scriptConverter = ScriptConverter()

        addressConverter = SegWitBech32AddressConverter(
            prefix: networkParams.bech32PrefixPattern,
            scriptConverter: scriptConverter
        )
    }
}

// MARK: - BitcoinScriptAddressProvider

extension Fact0rnAddressService: BitcoinScriptAddressProvider {
    func makeScriptAddress(from scriptHash: Data) throws -> String {
        return try addressConverter.convert(scriptHash: scriptHash).stringValue
    }
}

// MARK: - AddressProvider

extension Fact0rnAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let bitcoinCorePublicKey = PublicKey(
            withAccount: 0,
            index: 0,
            external: true,
            hdPublicKeyData: compressedKey
        )

        let address = try addressConverter.convert(publicKey: bitcoinCorePublicKey, type: .p2wpkh).stringValue
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

extension Fact0rnAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        let segwitAddress = try? addressConverter.convert(address: address)
        return segwitAddress != nil
    }
}
