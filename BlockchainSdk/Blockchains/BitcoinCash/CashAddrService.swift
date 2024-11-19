//
//  CashAddrService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import TangemSdk

@available(iOS 13.0, *)
class CashAddrService {
    private let addressPrefix: String

    init(networkParams: INetwork) {
        addressPrefix = networkParams.bech32PrefixPattern
    }

    func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let prefix = Data([UInt8(0x00)]) // public key hash
        let payload = compressedKey.sha256Ripemd160
        let walletAddress = CashAddrBech32.encode(prefix + payload, prefix: addressPrefix)
        return walletAddress
    }

    func validate(_ address: String) -> Bool {
        let address = address.firstIndex(of: ":") == nil ? "\(addressPrefix):\(address)" : address

        guard let decoded = CashAddrBech32.decode(address) else {
            return false
        }

        let raw = decoded.data
        let versionByte = raw[0]
        let hash = raw.dropFirst()

        guard hash.count == BitcoinCashVersionByte.getSize(from: versionByte) else {
            return false
        }

        guard BitcoinCashVersionByte.TypeBits(rawValue: versionByte & 0b01111000) != nil else {
            return false
        }

        return true
    }
}

// MARK: - BitcoinCashVersionByte

private class BitcoinCashVersionByte {
    var type: TypeBits { return .pubkeyHash }
    var size: SizeBits { return .size160 }

    static func getSize(from versionByte: UInt8) -> Int {
        guard let sizeBits = SizeBits(rawValue: versionByte & 0x07) else {
            return 0
        }
        switch sizeBits {
        case .size160:
            return 20
        case .size192:
            return 24
        case .size224:
            return 28
        case .size256:
            return 32
        case .size320:
            return 40
        case .size384:
            return 48
        case .size448:
            return 56
        case .size512:
            return 64
        }
    }

    // First 1 bit is zero
    // Next 4bits
    enum TypeBits: UInt8 {
        case pubkeyHash = 0
        case scriptHash = 8
    }

    // The least 3bits
    enum SizeBits: UInt8 {
        case size160 = 0
        case size192 = 1
        case size224 = 2
        case size256 = 3
        case size320 = 4
        case size384 = 5
        case size448 = 6
        case size512 = 7
    }
}
