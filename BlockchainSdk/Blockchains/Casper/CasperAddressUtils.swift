//
//  CasperAddressUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift

/*
 https://github.com/casper-ecosystem/casper-js-sdk/blob/dev/src/lib/ChecksummedHex.ts
 */

struct CasperAddressUtils {
    // Ed25519: encode([0x01]) + encode(<public key bytes>)
    // or
    // Secp256k1: encode([0x02]) + encode(<public key bytes>)
    func checksum(input: Data) throws -> String {
        let byteArray = input.bytes

        guard byteArray.count > 2, let first = byteArray.first else {
            throw Error.failedSizeInputChecksum
        }

        return try encode(input: [first]) + encode(input: Array(input.bytes[1 ..< input.count]))
    }

    // MARK: - Private Implementation

    // Separate bytes inside ByteArray to nibbles
    // E.g. [0x01, 0x55, 0xFF, ...] -> [0x00, 0x01, 0x50, 0x05, 0xF0, 0x0F, ...]
    private func bytesToNibbles(bytes: [UInt8]) -> [UInt8] {
        let result: [UInt8] = bytes.reduce(into: []) { partialResult, byte in
            partialResult.append((byte & 0xFF) >> 4)
            partialResult.append(byte & 0x0F)
        }

        return result
    }

    private func byteHash(bytes: [UInt8]) throws -> [UInt8] {
        guard let hashData = Data(bytes).hashBlake2b(outputLength: 32) else {
            throw Error.failedHashBlake2b
        }
        return hashData.bytes
    }

    private func encode(input: [UInt8]) throws -> String {
        let inputNibbles = bytesToNibbles(bytes: input)
        let hash = try byteHash(bytes: input)

        // Separate bytes inside ByteArray to bits array
        // E.g. [0x01, ...] -> [false, false, false, false, false, false, false, true, ...]
        // E.g. [0xAA, ...] -> [true, false, true, false, true, false, true, false, ...]
        let hashBits = hash.toBitArray().map { $0.boolValue }

        var hashBitsValues = hashBits.makeIterator()

        let result: String = inputNibbles.reduce(into: "") { partialResult, nibbleByte in
            let char = String(format: "%X", nibbleByte)

            if char.range(of: Constants.regexEncodeByte, options: .regularExpression) != nil, hashBitsValues.next() ?? false {
                partialResult.append(char.uppercased())
            } else {
                partialResult.append(char.lowercased())
            }
        }

        return result
    }
}

extension CasperAddressUtils {
    enum Constants {
        static let regexEncodeByte = "^[a-zA-Z()]+"
    }

    enum Error: LocalizedError {
        case failedSizeInputChecksum
        case failedHashBlake2b
    }
}

private extension Bit {
    var boolValue: Bool {
        self == .one
    }
}

private extension UInt8 {
    func toBits() -> [Bit] {
        var byte = self
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0 ..< 8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }

            byte >>= 1
        }

        return bits
    }
}

private extension Array where Element == UInt8 {
    func toBitArray() -> [Bit] {
        flatMap { $0.toBits() }
    }
}
