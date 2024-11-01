//
//  Decimal+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    /// return 8 bytes of integer. LittleEndian  format
    var bytes8LE: [UInt8] {
        let int64value = (rounded(scale: 0) as NSDecimalNumber).intValue
        let bytes8 = int64value.bytes8LE
        return Array(bytes8)
    }

    init?(_ int: Int?) {
        guard let int = int else {
            return nil
        }

        self.init(int)
    }

    init?(data: Data) {
        guard let uint64 = UInt64(data: data) else {
            return nil
        }

        self.init(uint64)
    }

    public func rounded(scale: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }

    func rounded(blockchain: Blockchain, roundingMode: RoundingMode = .down) -> Decimal {
        return rounded(scale: Int(blockchain.decimalCount), roundingMode: roundingMode)
    }

    mutating func round(scale: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .down) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }

    var int64Value: Int64 {
        decimalNumber.int64Value
    }

    var uint64Value: UInt64 {
        decimalNumber.uint64Value
    }

    var decimalNumber: NSDecimalNumber {
        self as NSDecimalNumber
    }

    var roundedDecimalNumber: NSDecimalNumber {
        rounded(roundingMode: .up) as NSDecimalNumber
    }

    func isEqual(to value: Decimal, delta: Decimal) -> Bool {
        abs(self - value) <= delta
    }
}

// MARK: - Point moving

extension Decimal {
    func moveRight(decimals: Int) -> Decimal {
        self * pow(10, decimals)
    }

    func moveLeft(decimals: Int) -> Decimal {
        self / pow(10, decimals)
    }
}
