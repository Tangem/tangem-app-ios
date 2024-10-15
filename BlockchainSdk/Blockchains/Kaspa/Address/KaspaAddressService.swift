//
//  KaspaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

@available(iOS 13.0, *)
public class KaspaAddressService {
    private let isTestnet: Bool
    private let prefix: String
    private let version: KaspaAddressComponents.KaspaAddressType = .P2PK_ECDSA

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        // TODO: Does testnet support ecdsa type addresses? If not, then we are not ready to work with different curves (secp256k1/schnorr) for now
        self.prefix = isTestnet ? "kaspatest" : "kaspa"
    }
    
    func parse(_ address: String) -> KaspaAddressComponents? {
        guard
            let (prefix, data) = CashAddrBech32.decode(address),
            !data.isEmpty,
            let firstByte = data.first,
            let type = KaspaAddressComponents.KaspaAddressType(rawValue: firstByte)
        else {
            return nil
        }

        return KaspaAddressComponents(
            prefix: prefix,
            type: type,
            hash: data.dropFirst()
        )
    }
}


// MARK: - AddressProvider

@available(iOS 13.0, *)
extension KaspaAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let address = CashAddrBech32.encode(version.rawValue.data + compressedKey, prefix: prefix)
        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension KaspaAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        guard
            let components = parse(address),
            components.prefix == self.prefix
        else {
            return false
        }

        let validStartLetters = ["q", "p"]
        guard
            let firstAddressLetter = address.dropFirst(prefix.count + 1).first,
            validStartLetters.contains(String(firstAddressLetter))
        else {
            return false
        }

        return true
    }
}
