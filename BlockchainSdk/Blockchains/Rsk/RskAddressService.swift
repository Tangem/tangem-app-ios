//
//  RskAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift

struct RskAddressService {
    private func toChecksumAddress(_ address: String) -> String? {
        let lowercasedAddress = address.lowercased()
        let addressToHash = "30\(lowercasedAddress)"
        guard let hash = addressToHash.data(using: .utf8)?.sha3(.keccak256).hexString.lowercased().removeHexPrefix() else {
            return nil
        }

        var ret = "0x"
        let hashChars = Array(hash)
        let addressChars = Array(lowercasedAddress.removeHexPrefix())
        for i in 0 ..< addressChars.count {
            guard let intValue = Int(String(hashChars[i]), radix: 16) else {
                return nil
            }

            if intValue >= 8 {
                ret.append(addressChars[i].uppercased())
            } else {
                ret.append(addressChars[i])
            }
        }
        return ret
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension RskAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        // skip secp256k1 prefix
        let walletPublicKey = try Secp256k1Key(with: publicKey.blockchainKey).decompress()
        let keccak = walletPublicKey[1...].sha3(.keccak256)
        let addressBytes = keccak[12...]
        let address = addressBytes.hexString.addHexPrefix()
        let checksumAddress = toChecksumAddress(address)!
        return PlainAddress(value: checksumAddress, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension RskAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard !address.isEmpty,
              address.hasHexPrefix(),
              address.count == 42
        else {
            return false
        }

        if let checksummed = toChecksumAddress(address),
           checksummed == address {
            return true
        } else {
            let cleanHex = address.stripHexPrefix()
            if cleanHex.lowercased() != cleanHex, cleanHex.uppercased() != cleanHex {
                return false
            }
        }

        return true
    }
}
