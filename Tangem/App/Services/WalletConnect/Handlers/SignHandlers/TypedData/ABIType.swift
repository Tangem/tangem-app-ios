// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public indirect enum ABIType: Equatable, CustomStringConvertible {
    /// Unsigned integer with `0 < bits <= 256`, `bits % 8 == 0`
    case uint(bits: Int)

    /// Signed integer with `0 < bits <= 256`, `bits % 8 == 0`
    case int(bits: Int)

    /// Address, similar to `uint(bits: 160)`
    case address

    /// Boolean
    case bool

    /// Binary type of `M` bytes, `0 < M <= 32`.
    case bytes(Int)

    /// Fixed-length array of M elements, `M > 0`, of the given type.
    case array(ABIType, Int)

    /// Dynamic-sized string
    case string

    /// Tuple consisting of elements of the given types
    case tuple([ABIType])

    /// Type description
    ///
    /// This is the string as required for function selectors
    public var description: String {
        switch self {
        case .uint(let bits):
            return "uint\(bits)"
        case .int(let bits):
            return "int\(bits)"
        case .address:
            return "address"
        case .bool:
            return "bool"
        case .bytes(let size):
            return "bytes\(size)"
        case .array(let type, let size):
            return "\(type)[\(size)]"
        case .string:
            return "string"
        case .tuple(let types):
            return types.reduce("", { $0 + $1.description })
        }
    }
}
