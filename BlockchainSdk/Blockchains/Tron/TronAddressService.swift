//
//  TronAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift

struct TronAddressService {
    private let prefix: UInt8 = 0x41
    private let addressLength = 21
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension TronAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let decompressedPublicKey = try Secp256k1Key(with: publicKey.blockchainKey).decompress()

        let data = decompressedPublicKey.dropFirst()
        let hash = data.sha3(.keccak256)

        let addressData = [prefix] + hash.suffix(addressLength - 1)
        let address = addressData.base58CheckEncodedString

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension TronAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let decoded = address.base58CheckDecodedBytes else {
            return false
        }

        return decoded.starts(with: [prefix]) && decoded.count == addressLength
    }
}
