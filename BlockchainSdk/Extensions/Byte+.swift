//
//  Byte+.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift

extension Bit {
    var boolValue: Bool {
        self == .one
    }
}

extension UInt8 {
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

extension Array where Element == UInt8 {
    func toBitArray() -> [Bit] {
        let arrayBits = map { $0.toBits() }
        return arrayBits.reduce(into: []) { partialResult, bits in partialResult.append(contentsOf: bits) }
    }
}
