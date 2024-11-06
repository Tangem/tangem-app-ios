//
//  String+.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    var dropTrailingPeriod: SubSequence { hasSuffix(".") ? dropLast(1) : self[...] }

    var hexToInteger: Int? { Int(removeHexPrefix(), radix: 16) }

    var integerToHex: String { .init(Int(self) ?? 0, radix: 16) }

    func removeLatestSlash() -> String {
        if last == "/" {
            return String(dropLast())
        }

        return self
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }

    func remove(contentsOf strings: [String]) -> String {
        strings.reduce(into: self) {
            $0 = $0.remove($1)
        }
    }

    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func camelCaseToSnakeCase() -> String {
        let regex = try! NSRegularExpression(pattern: "([A-Z])", options: [])
        let range = NSRange(location: 0, length: count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "_$1").lowercased()
    }

    func caseInsensitiveContains(_ other: some StringProtocol) -> Bool {
        return range(of: other, options: .caseInsensitive) != nil
    }
}
