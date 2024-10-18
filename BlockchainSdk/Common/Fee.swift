//
//  Fee.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FeeParameters {}

public struct Fee {
    public let amount: Amount
    public let parameters: FeeParameters?

    public init(_ fee: Amount, parameters: FeeParameters? = nil) {
        amount = fee
        self.parameters = parameters
    }
}

// MARK: - Hashable

extension Fee: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
    }

    public static func == (lhs: Fee, rhs: Fee) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension Fee: CustomStringConvertible {
    public var description: String {
        var string = "Fee: \(amount.description)"
        if let parameters {
            string += "\nFee parameters: \(parameters)"
        }
        return string
    }
}
