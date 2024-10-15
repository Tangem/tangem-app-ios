//
//  String+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

fileprivate var hexPrefix = "0x"

extension String {
    func contains(_ string: String, ignoreCase: Bool = true) -> Bool {
        return self.range(of: string, options: ignoreCase ? .caseInsensitive : []) != nil
    }

    func caseInsensitiveEquals(to other: some StringProtocol) -> Bool {
        return caseInsensitiveCompare(other) == .orderedSame
    }

    public func hasHexPrefix() -> Bool {
        return self.lowercased().hasPrefix(hexPrefix)
    }

    public func removeHexPrefix() -> String {
        if hasHexPrefix() {
            return String(dropFirst(2))
        }
        
        return self
    }

    public func addHexPrefix() -> String {
        if lowercased().hasPrefix(hexPrefix) {
            return self
        }

        return hexPrefix.appending(self)
    }

    func removeBchPrefix() -> String {
        if let index = self.firstIndex(where: { $0 == ":" }) {
            let startIndex = self.index(index, offsetBy: 1)
            return String(self.suffix(from: startIndex))
        }

        return self
    }
    
    func stripLeadingZeroes() -> String {
        self.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
    }

    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }

    var toUInt8: [UInt8] {
        let v = self.utf8CString.map({ UInt8($0) })
        return Array(v[0 ..< (v.count-1)])
    }
    
    var isValidHex: Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

        let found = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count))

        if found == nil || found?.range.location == NSNotFound || count % 2 != 0 {
            return false
        }

        return true
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    var localized: String {
        return NSLocalizedString(self, bundle: .blockchainBundle, comment: "")
    }
    
    func localized(_ arguments: [CVarArg]) -> String {
        return String(format: localized, arguments: arguments)
    }

    func localized(_ argument: CVarArg) -> String {
        return String(format: localized, argument)
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(self.startIndex, offsetBy: bounds.lowerBound)
        let end = index(self.startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    public static var unknown: String {
        "Unknown"
    }
    
    func base64URLToBase64() -> String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    /// Decodes a Base64 URL-safe encoded string to Data
    func base64URLDecodedData() -> Data? {
        let base64 = self.base64URLToBase64()
        return Data(base64Encoded: base64)
    }
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
