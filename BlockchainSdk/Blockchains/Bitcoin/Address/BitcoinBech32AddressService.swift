//
//  BitcoinBech32AddressService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import TangemSdk

@available(iOS 13.0, *)
class BitcoinBech32AddressService {
    private let segWitConverter: SegWitBech32AddressConverter
    private let tapRootConverter: TaprootAddressConverter

    init(networkParams: INetwork) {
        let scriptConverter = ScriptConverter()
        segWitConverter = SegWitBech32AddressConverter(
            prefix: networkParams.bech32PrefixPattern,
            scriptConverter: scriptConverter
        )
        tapRootConverter = TaprootAddressConverter(
            prefix: networkParams.bech32PrefixPattern,
            scriptConverter: scriptConverter
        )
    }
}

// MARK: - BitcoinScriptAddressProvider

@available(iOS 13.0, *)
extension BitcoinBech32AddressService: BitcoinScriptAddressProvider {
    func makeScriptAddress(from scriptHash: Data) throws -> String {
        return try segWitConverter.convert(scriptHash: scriptHash).stringValue
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinBech32AddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        let segwitAddress = try? segWitConverter.convert(address: address)
        let taprootAddress = try? tapRootConverter.convert(address: address)
        return segwitAddress != nil || taprootAddress != nil
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinBech32AddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let bitcoinCorePublicKey = PublicKey(
            withAccount: 0,
            index: 0,
            external: true,
            hdPublicKeyData: compressedKey
        )

        let address = try segWitConverter.convert(publicKey: bitcoinCorePublicKey, type: .p2wpkh).stringValue
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}
