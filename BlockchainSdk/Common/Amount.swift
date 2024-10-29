//
//  Amount.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct Amount: CustomStringConvertible, Hashable, Comparable {
    public enum AmountType {
        case coin
        case token(value: Token)
        case reserve
        case feeResource(FeeResourceType)

        public var token: Token? {
            if case .token(let token) = self {
                return token
            }
            return nil
        }

        public var isToken: Bool {
            return token != nil
        }
    }

    public let type: AmountType
    public let currencySymbol: String
    public var value: Decimal
    public let decimals: Int

    public var bigUIntValue: BigUInt? {
        if isZero {
            return BigUInt.zero
        }

        if value == Decimal.greatestFiniteMagnitude {
            return BigUInt(2).power(256) - 1
        }

        return EthereumUtils.parseToBigUInt("\(value)", decimals: decimals)
    }

    public var encoded: Data? {
        guard let bigUIntValue = bigUIntValue else {
            return nil
        }

        let amountData = bigUIntValue.serialize()
        return amountData
    }

    public var encodedForSend: String? {
        if isZero {
            return "0x0"
        }

        return encoded?.hexString.stripLeadingZeroes().addHexPrefix()
    }

    public var isZero: Bool {
        return value == 0
    }

    public var description: String {
        return string()
    }

    public init(
        type: AmountType,
        currencySymbol: String,
        value: Decimal,
        decimals: Int
    ) {
        self.type = type
        self.currencySymbol = currencySymbol
        self.value = value
        self.decimals = decimals
    }

    public init(
        with blockchain: Blockchain,
        type: AmountType = .coin,
        value: Decimal
    ) {
        self.type = type
        currencySymbol = type.token?.symbol ?? blockchain.currencySymbol
        decimals = type.token?.decimalCount ?? blockchain.decimalCount
        self.value = value
    }

    public init(
        with token: Token,
        value: Decimal
    ) {
        type = .token(value: token)
        currencySymbol = token.symbol
        decimals = token.decimalCount
        self.value = value
    }

    public init(
        with amount: Amount,
        value: Decimal
    ) {
        type = amount.type
        currencySymbol = amount.currencySymbol
        decimals = amount.decimals
        self.value = value
    }

    public func string(with decimals: Int? = nil, roundingMode: NSDecimalNumber.RoundingMode = .down) -> String {
        let decimalsCount = decimals ?? self.decimals
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencySymbol = currencySymbol
        formatter.alwaysShowsDecimalSeparator = true
        formatter.maximumFractionDigits = decimalsCount
        formatter.minimumFractionDigits = 2
        let rounded = value.rounded(scale: decimalsCount, roundingMode: roundingMode)
        return formatter.string(from: rounded as NSDecimalNumber) ??
            "\(rounded) \(currencySymbol)"
    }

    public static func == (lhs: Amount, rhs: Amount) -> Bool {
        if lhs.type != rhs.type {
            return false
        }

        return lhs.value == rhs.value
    }

    public static func - (l: Amount, r: Amount) -> Amount {
        if l.type != r.type {
            return l
        }
        return Amount(with: l, value: l.value - r.value)
    }

    public static func + (l: Amount, r: Amount) -> Amount {
        if l.type != r.type {
            return l
        }
        return Amount(with: l, value: l.value + r.value)
    }

    public static func < (lhs: Amount, rhs: Amount) -> Bool {
        if lhs.type != rhs.type {
            fatalError("Compared amounts must be the same type")
        }

        return lhs.value < rhs.value
    }
}

extension Amount.AmountType: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .coin:
            hasher.combine("coin")
        case .reserve:
            hasher.combine("reserve")
        case .token(let value):
            hasher.combine(value)
        case .feeResource(let type):
            hasher.combine(type)
        }
    }

    public static func == (lhs: Amount.AmountType, rhs: Amount.AmountType) -> Bool {
        switch (lhs, rhs) {
        case (.coin, .coin), (.reserve, .reserve):
            return true
        case (.token(let lv), .token(let rv)):
            return lv == rv
        case (.feeResource(let ln), .feeResource(let rn)):
            return ln == rn
        default:
            return false
        }
    }
}

public extension Amount {
    static func zeroCoin(for blockchain: Blockchain) -> Amount {
        .init(with: blockchain, type: .coin, value: 0)
    }

    static func maxCoin(for blockchain: Blockchain) -> Amount {
        .init(with: blockchain, type: .coin, value: Decimal.greatestFiniteMagnitude)
    }
}
