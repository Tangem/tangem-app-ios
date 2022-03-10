// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import BigInt
import Foundation

public indirect enum ABIValue: Equatable {
    /// Unsigned integer with `0 < bits <= 256`, `bits % 8 == 0`
    case uint(bits: Int, BigUInt)

    /// Signed integer with `0 < bits <= 256`, `bits % 8 == 0`
    case int(bits: Int, BigInt)

    /// Address, similar to `uint(bits: 160)`
    case address(EthereumAddress)

    /// Boolean
    case bool(Bool)

    /// Fixed-length bytes
    case bytes(Data)

    /// Fixed-length array where all values have the same type
    case array([ABIValue])

    /// String
    case string(String)

    /// Tuple
    case tuple([ABIValue])

    /// Encoded length in bytes
    public var length: Int {
        switch self {
        case .uint, .int, .address, .bool:
            return 32
        case .bytes(let data):
            return ((data.count + 31) / 32) * 32
        case .array(let values):
            return values.reduce(0, { $0 + $1.length })
        case .string(let string):
            let dataLength = string.data(using: .utf8)?.count ?? 0
            return 32 + ((dataLength + 31) / 32) * 32
        case .tuple(let array):
            return array.reduce(0, { $0 + $1.length })
        }
    }

    /// Whether the value is dynamic
    public var isDynamic: Bool {
        switch self {
        case .uint, .int, .address, .bool, .bytes, .array:
            return false
        case .string:
            return true
        case .tuple(let array):
            return array.contains(where: { $0.isDynamic })
        }
    }

    /// Creates a value from `Any` and an `ABIType`.
    ///
    /// - Throws: `ABIError.invalidArgumentType` if a value doesn't match the expected type.
    public init(_ value: Any, type: ABIType) throws {
        switch (type, value) {
        case (.uint(let bits), let value as Int):
            self = .uint(bits: bits, BigUInt(value))
        case (.uint(let bits), let value as UInt):
            self = .uint(bits: bits, BigUInt(value))
        case (.uint(let bits), let value as BigUInt):
            self = .uint(bits: bits, value)
        case (.int(let bits), let value as Int):
            self = .int(bits: bits, BigInt(value))
        case (.int(let bits), let value as BigInt):
            self = .int(bits: bits, value)
        case (.address, let address as EthereumAddress):
            self = .address(address)
        case (.bool, let value as Bool):
            self = .bool(value)
        case (.bytes(let size), let data as Data):
            if data.count > size {
                self = .bytes(data[..<size])
            } else {
                self = .bytes(data)
            }
        case (.array, let values as [ABIValue]):
            self = .array(values)
        case (.string, let string as String):
            self = .string(string)
        case (.tuple(let types), let array as [Any]):
            self = .tuple(try zip(types, array).map({ try ABIValue($1, type: $0) }))
        default:
            throw ABIError.invalidArgumentType
        }
    }
}
