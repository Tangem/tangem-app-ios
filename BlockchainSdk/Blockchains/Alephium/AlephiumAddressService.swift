//
//  AlephiumAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct AlephiumAddressService {}

// MARK: - AddressProvider

extension AlephiumAddressService: AddressProvider, AddressValidator {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()

        guard let blake2bHash = compressedKey.hashBlake2b(outputLength: 32) else {
            throw Error.undefinedBlake2bHash
        }

        let hashData = Data(hexString: Prefix.value()) + blake2bHash
        let address = Base58.encode(hashData)

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }

    func validate(_ address: String) -> Bool {
        return false
    }
}

// MARK: - Helpers

extension AlephiumAddressService {
    enum Prefix {
        static let prefix = "00"

        static func value() -> String {
            prefix.addHexPrefix()
        }
    }

    enum Error: LocalizedError {
        case undefinedBlake2bHash
    }
}
