//
//  AlephiumAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AlephiumAddressService {}

// MARK: - AddressProvider

extension AlephiumAddressService: AddressProvider, AddressValidator {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()

        guard let blake2bHash = compressedKey.hashBlake2b(outputLength: 32) else {
            throw Error.undefinedBlake2bHash
        }

        let hashData = Data(hexString: Constants.prefixAddressValue.addHexPrefix()) + blake2bHash
        let address = hashData.base58EncodedString

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }

    func validate(_ address: String) -> Bool {
        let hexDataString = address.base58DecodedData.hexString
        let withoutHexString = hexDataString.removeHexPrefix()
        return withoutHexString.hasPrefix(Constants.prefixAddressValue) && withoutHexString.count == 66
    }
}

// MARK: - Helpers

extension AlephiumAddressService {
    enum Constants {
        static let prefixAddressValue = "00"
    }

    enum Error: LocalizedError {
        case undefinedBlake2bHash
    }
}
