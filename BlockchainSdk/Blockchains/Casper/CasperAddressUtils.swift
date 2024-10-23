//
//  CasperAddressUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Blake2

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
        
        return try encode(input: [first]) + encode(input: Array(input.bytes[1..<input.count]))
    }
    
    // MARK: - Private Implementation
    
    // Separate bytes inside ByteArray to nibbles
    // E.g. [0x01, 0x55, 0xFF, ...] -> [0x00, 0x01, 0x50, 0x05, 0xF0, 0x0F, ...]
    private func bytesToNibbles(bytes: [UInt8]) -> [UInt8] {
        let result: [UInt8] = bytes.reduce(into: [], { partialResult, byte in
            partialResult.append((byte & 0xFF) >> 4)
            partialResult.append(byte & 0x0F)
        })
        
        return result
    }
    
    private func byteHash(bytes: [UInt8]) throws -> [UInt8] {
        guard let hashData = try? Blake2b.hash(size: 32, data: bytes) else {
            throw Error.failedHashBlake2b
        }
        return hashData.bytes
    }
    
    private func encode(input: [UInt8]) throws -> String {
        let inputNibbles = bytesToNibbles(bytes: input)
        
        print(inputNibbles.toHexString())
        
        let hash = try byteHash(bytes: input)
        
        print(hash.toHexString())
        
        // Separate bytes inside ByteArray to bits array
        // E.g. [0x01, ...] -> [false, false, false, false, false, false, false, true, ...]
        // E.g. [0xAA, ...] -> [true, false, true, false, true, false, true, false, ...]
        let hashBits = hash.toBitArray().map { $0.boolValue }
        
        print(hashBits)
        
        var hashBitsValues = hashBits.makeIterator()
        
        print(hashBitsValues)
        
        let result: String = inputNibbles.reduce(into: "") { partialResult, nibbleByte in
            let char = nibbleByte.hexString
            
            if char.range(of: "[^a-zA-Z0-9-]", options: .regularExpression) == nil, hashBitsValues.next() ?? false {
                partialResult.append(char.lowercased())
            } else {
                partialResult.append(char.uppercased())
            }
        }
        
        print(result)
        
        return result
    }
}

extension CasperAddressUtils {
    enum Constants {
        static let regexEncodeByte = try! NSRegularExpression(pattern: "^[a-zA-Z()]")
    }
    
    enum Error: LocalizedError {
        case failedSizeInputChecksum
        case failedHashBlake2b
    }
}

/*
/**
 * @see <a href="https://github.com/casper-ecosystem/casper-js-sdk/blob/dev/src/lib/ChecksummedHex.ts">Source</a>
 */
object CasperAddressUtils {
    // Ed25519: encode([0x01]) + encode(<public key bytes>)
    // or
    // Secp256k1: encode([0x02]) + encode(<public key bytes>)
    fun ByteArray.checksum(): String = encode(byteArrayOf(first())) + encode(drop(1).toByteArray())

    // Separate bytes inside ByteArray to nibbles
    // E.g. [0x01, 0x55, 0xFF, ...] -> [0x00, 0x01, 0x50, 0x05, 0xF0, 0x0F, ...]
    @Suppress("MagicNumber")
    private fun bytesToNibbles(bytes: ByteArray): ByteArray = bytes
        .flatMap { byte ->
            listOf(
                (byte.toInt() and 0xff shr 4).toByte(),
                (byte.toInt() and 0x0f).toByte(),
            )
        }.toByteArray()

    // Separate bytes inside ByteArray to bits array
    // E.g. [0x01, ...] -> [false, false, false, false, false, false, false, true, ...]
    // E.g. [0xAA, ...] -> [true, false, true, false, true, false, true, false, ...]
    @Suppress("MagicNumber")
    private fun ByteArray.toBitArray(): BooleanArray = this
        .flatMap { byte ->
            List(8) { i ->
                byte.toInt() shr i and 0x01 == 0x01
            }
        }.toBooleanArray()

    private fun byteHash(bytes: ByteArray): ByteArray = Blake2b.Blake2b256().digest(bytes)

    private fun encode(input: ByteArray): String {
        val inputNibbles = bytesToNibbles(input)
        val hash = byteHash(input)
        val hashBits = hash.toBitArray()
        val hashBitsValues = hashBits.iterator()
        return inputNibbles.fold(StringBuilder()) { accum, nibble ->
            val c = "%x".format(nibble)

            if (Regex("^[a-zA-Z()]+\$").matches(c) && hashBitsValues.hasNext() && hashBitsValues.next()) {
                accum.append(c.uppercase())
            } else {
                accum.append(c.lowercase())
            }
            accum
        }.toString()
    }
}
*/
