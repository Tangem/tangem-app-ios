//
//  SS58.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

/// Set of tools for working with ss58
struct SS58 {
    /// If data is bigger than 32 bytes we need to hash it, otherwise just return plain data
    /// - Parameter data: public key data
    /// - Returns: either plain or hashed data
    func accountData(from data: Data) -> Data {
        guard data.count > Constants.publicKeySize else { return data }
        return data.blake2hash(outputLength: Int(Constants.publicKeySize))
    }

    /// The network type from provided address
    /// see https://github.com/paritytech/ss58-registry/blob/main/ss58-registry.json `prefix` value
    /// - Parameter address: Base58 encoded address, e.g. j4UiniaZ4GBrMQmjFPapb4fKMmXHxsPbVF4Lny1jHXSuWBKTS
    /// - Returns: The network type
    func networkType(from address: String) throws -> UInt {
        let decodedData = address.base58DecodedData

        guard decodedData.count >= Constants.maxPrefixSize else {
            throw Error.invalidAddress
        }

        let first = UInt(decodedData[0])

        guard first >= Constants.rangeLimit else {
            return first
        }

        let second = UInt(decodedData[1])
        let lo = ((first & 0x3f) << 2) | (second >> 6)
        let hi = (second & 0x3f) << 8

        return lo | hi
    }

    /// Base58 encoded address for network
    /// - Parameter data: data from accountData(from:)
    /// - Parameter type: see https://github.com/paritytech/ss58-registry/blob/main/ss58-registry.json `prefix` value
    /// - Returns: Base58 encoded address string, e.g. j4UiniaZ4GBrMQmjFPapb4fKMmXHxsPbVF4Lny1jHXSuWBKTS
    func address(from data: Data, type: UInt) -> String {
        let networkCode = UInt16(type) & 0b0011_1111_1111_1111
        var result: [UInt8]

        if networkCode < Constants.rangeLimit {
            result = [UInt8(networkCode)]
        } else {
            let first = UInt8(((networkCode & 0b0000_0000_1111_1100) >> 2) & 0xFF) | 0b01000000
            let second = UInt8(((networkCode >> 8) & 0xFF) | ((networkCode & 0b0000_0000_0000_0011) << 6))
            result = [first, second]
        }

        result += data
        result += checksum(for: Data(result))
        return Data(result).base58EncodedString
    }

    /// Raw representation (without the prefix) was used in the older protocol versions
    /// - Parameter string: Base58 encoded address string, e.g. j4UiniaZ4GBrMQmjFPapb4fKMmXHxsPbVF4Lny1jHXSuWBKTS
    /// - Returns: Base58 decoded data without ss58 prefix and checksum
    func bytes(string: String, raw: Bool = true) -> Data {
        var decoded = string.base58DecodedData
        guard let networkTypeBytes = try? networkType(from: string) else {
            return decoded
        }
        decoded.removeFirst(networkTypeBytes >= Constants.rangeLimit ? 2 : 1)
        decoded.removeLast(Constants.checksumSize)
        if !raw {
            decoded = Data(UInt8(0)) + decoded
        }
        return decoded
    }

    /// Checks if provided address is valid for network type
    /// - Parameter address: Base58 encoded address string, e.g. j4UiniaZ4GBrMQmjFPapb4fKMmXHxsPbVF4Lny1jHXSuWBKTS
    /// - Parameter type: see https://github.com/paritytech/ss58-registry/blob/main/ss58-registry.json `prefix` value
    /// - Returns: true if address is valid, otherwise false
    func isValidAddress(_ address: String, type: UInt) -> Bool {
        let data = address.base58DecodedData

        guard let networkType = try? networkType(from: address),
              networkType == type else { return false }

        let expectedChecksum = data.suffix(Constants.checksumSize)
        let addressData = data.dropLast(Constants.checksumSize)

        let checksum = checksum(for: addressData)

        return checksum == expectedChecksum
    }

    /// Calculates checksum using blake2hash
    /// - Returns: checksum
    func checksum(for data: Data) -> Data {
        let hash = (Constants.prefix + data).blake2hash(outputLength: 64)
        let checksum = Data(hash).prefix(Constants.checksumSize)
        return checksum
    }
}

private extension SS58 {
    enum Constants {
        static let publicKeySize: UInt = 32
        static let prefix = "SS58PRE".data(using: .utf8) ?? Data()
        static let maxPrefixSize: UInt = 2
        static let checksumSize: Int = 2
        static let rangeLimit: UInt16 = 64
    }

    enum Error: Swift.Error {
        case invalidAddress
    }
}

// TODO: Use extension from Data+ and refactor call stack to handle optional Data
private extension Data {
    func blake2hash(outputLength: Int) -> Data {
        guard let hash = Sodium().genericHash.hash(message: bytes, outputLength: outputLength) else {
            return Data([])
        }
        return Data(hash)
    }
}
