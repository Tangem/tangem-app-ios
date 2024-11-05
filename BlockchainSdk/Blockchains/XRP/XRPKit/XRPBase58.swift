//
//  XRPBase58.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum XRPBase58 {
    fileprivate static let xrpAlphabet = [UInt8]("rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz".utf8)

    /// returns string preserving leading zeroes
    static func getString(from data: Data) -> String {
        return String(base58: data, alphabet: XRPBase58.xrpAlphabet)
    }

    /// returns data with stripped zeroes
    static func getData(from string: String) -> Data? {
        return Data(base58: string, alphabet: XRPBase58.xrpAlphabet)
    }
}

private extension String {
    init(base58 bytes: Data, alphabet: [UInt8]) {
        var bigInt = BigUInt(bytes)
        let radix = BigUInt(alphabet.count)

        var answer = [UInt8]()
        answer.reserveCapacity(bytes.count)

        while bigInt > 0 {
            let (quotient, modulus) = bigInt.quotientAndRemainder(dividingBy: radix)
            answer.append(alphabet[Int(modulus)])
            bigInt = quotient
        }

        let zerosCount = bytes.prefix(while: { $0 == 0 }).count
        let prefix = Array(repeating: alphabet[0], count: zerosCount)
        let result = prefix + answer.reversed()

        self = String(bytes: result, encoding: String.Encoding.utf8)!
    }
}

private extension Data {
    init?(base58 string: String, alphabet: [UInt8]) {
        var answer = BigUInt(0)
        var j = BigUInt(1)
        let radix = BigUInt(alphabet.count)
        let byteString = [UInt8](string.utf8)

        for ch in byteString.reversed() {
            if let index = alphabet.firstIndex(of: ch) {
                answer = answer + (j * BigUInt(index))
                j *= radix
            } else {
                return nil
            }
        }

        let bytes = answer.serialize()
        self = bytes
    }
}
