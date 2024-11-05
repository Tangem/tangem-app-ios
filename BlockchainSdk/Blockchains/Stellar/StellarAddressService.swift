//
//  StellarAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

struct StellarAddressService {}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension StellarAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsEdKey()

        let stellarPublicKey = try PublicKey(Array(publicKey.blockchainKey))
        let keyPair = KeyPair(publicKey: stellarPublicKey)
        let address = keyPair.accountId

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension StellarAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        /// Need verify for use KeyPair(accountId: address) in library stellar-sdk for skip bad condition [Array(([UInt8](data))[1...data.count - 3])]
        guard let baseData = address.base32DecodedData, baseData.count >= 4 else {
            return false
        }

        let keyPair = try? KeyPair(accountId: address)
        return keyPair != nil
    }
}
