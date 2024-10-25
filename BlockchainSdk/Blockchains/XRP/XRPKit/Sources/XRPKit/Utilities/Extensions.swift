//
//  Extensions.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

func sha512HalfHash(data: [UInt8]) -> [UInt8] {
    return [UInt8](Data(data).sha512().prefix(through: 31))
}

extension Data {
    mutating func getPointer() -> UnsafeMutablePointer<UInt8> {
        return withUnsafeMutableBytes { bytePtr in
            bytePtr.bindMemory(to: UInt8.self).baseAddress!
        }
    }

    func sha512Half() -> Data {
        Data(sha512().prefix(through: 31))
    }
}

extension Data {
    init(xrpHex hex: String) {
        var data = Data(capacity: hex.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hex, options: [], range: NSMakeRange(0, hex.count)) { match, flags, stop in
            let byteString = (hex as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        self = data
    }
}

extension String {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

typealias Byte = UInt8
enum Bit: Int {
    case zero
    case one
}

// extension Data {
//    var bytes: [Byte] {
//        var byteArray = [UInt8](repeating: 0, count: self.count)
//        self.copyBytes(to: &byteArray, count: self.count)
//        return byteArray
//    }
// }

extension Byte {
    var bits: [Bit] {
        let bitsOfAbyte = 8
        var bitsArray = [Bit](repeating: Bit.zero, count: bitsOfAbyte)
        for (index, _) in bitsArray.enumerated() {
            // Bitwise shift to clear unrelevant bits
            let bitVal: UInt8 = 1 << UInt8(bitsOfAbyte - 1 - index)
            let check = self & bitVal

            if check != 0 {
                bitsArray[index] = Bit.one
            }
        }
        return bitsArray
    }
}

extension String {
    /// Create `Data` from hexadecimal string representation
    ///
    /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.

    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        guard !data.isEmpty else { return nil }

        return data
    }
}

extension Data {
    /// Hexadecimal string representation of `Data` object.

    var hexadecimal: String {
        return map { String(format: "%02x", $0) }
            .joined()
    }
}

extension Numeric {
    var data: Data {
        var source = self
        return withUnsafeBytes(of: &source) { Data($0) }
    }
}

extension URL {
    static let xrpl_rpc_MainNetS1 = URL(string: "https://s1.ripple.com:51234/")!
    static let xrpl_rpc_MainNetS2 = URL(string: "https://s2.ripple.com:51234/")!
    static let xrpl_rpc_Testnet = URL(string: "https://s.altnet.rippletest.net:51234/")!
    static let xrpl_rpc_Devnet = URL(string: "https://s.devnet.rippletest.net:51234/")!
    static let xrpl_ws_MainnetS1 = URL(string: "wss://s1.ripple.com/")!
    static let xrpl_ws_MainnetS2 = URL(string: "wss://s2.ripple.com/")!
    static let xrpl_ws_Testnet = URL(string: "wss://s.altnet.rippletest.net/")!
    static let xrpl_ws_Devnet = URL(string: "wss://s.devnet.rippletest.net/")!
}
