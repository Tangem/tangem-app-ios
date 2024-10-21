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
public class CashAddrService {
    private let addressPrefix: String

    public init(networkParams: INetwork) {
        addressPrefix = networkParams.bech32PrefixPattern
    }

    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = compressedKey.sha256Ripemd160
        let walletAddress = CashAddrBech32.encode(prefix + payload, prefix: addressPrefix)
        return walletAddress
    }

    public func validate(_ address: String) -> Bool {
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

        guard BitcoinCashVersionByte.TypeBits(rawValue: (versionByte & 0b01111000)) != nil else {
            return false
        }

        return true
    }
}

// MARK: - BitcoinCashVersionByte

fileprivate class BitcoinCashVersionByte {
    public var type: TypeBits { return .pubkeyHash }
    public var size: SizeBits { return .size160 }

    public static func getSize(from versionByte: UInt8) -> Int {
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
    public enum TypeBits: UInt8 {
        case pubkeyHash = 0
        case scriptHash = 8
    }

    // The least 3bits
    public enum SizeBits: UInt8 {
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
