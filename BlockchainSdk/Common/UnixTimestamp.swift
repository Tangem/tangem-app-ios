//
//  UnixTimestamp.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 22.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// UNIX timestamp, with an optional fractional part (nanoseconds).
struct UnixTimestamp {
    let seconds: UInt
    let nanoseconds: UInt
}

// MARK: - Private implementation

private extension UnixTimestamp {
    init?(signedSeconds: Int, signedNanoseconds: Int) {
        // UNIX timestamps can't be negative
        guard signedSeconds >= 0, signedNanoseconds >= 0 else {
            return nil
        }

        self.init(seconds: UInt(signedSeconds), nanoseconds: UInt(signedNanoseconds))
    }
}

// MARK: - Convenience extensions

extension UnixTimestamp {
    init?<T>(timestamp: T) where T: BinaryInteger {
        self.init(signedSeconds: Int(timestamp), signedNanoseconds: 0)
    }

    /// - Warning: `NSDate`/`Swift.Date` provides only milliseconds precision https://stackoverflow.com/questions/46161848
    init?(date: Date) {
        let referenceDate = Date(timeIntervalSince1970: 0.0)
        let dateComponents = Calendar.current.dateComponents([.second, .nanosecond], from: referenceDate, to: date)

        self.init(
            signedSeconds: dateComponents.second ?? 0,
            signedNanoseconds: dateComponents.nanosecond ?? 0
        )
    }
}

// MARK: - ExpressibleByIntegerLiteral protocol conformance

extension UnixTimestamp: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt

    init(integerLiteral value: IntegerLiteralType) {
        self.init(seconds: value, nanoseconds: 0)
    }
}
