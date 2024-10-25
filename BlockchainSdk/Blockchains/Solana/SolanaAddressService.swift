//
//  SolanaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct SolanaAddressService {}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension SolanaAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsEdKey()
        let address = Base58.encode(publicKey.blockchainKey.bytes)

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension SolanaAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let publicKey = PublicKey(string: address) else {
            return false
        }
        return publicKey.bytes.count == PublicKey.LENGTH
    }
}
