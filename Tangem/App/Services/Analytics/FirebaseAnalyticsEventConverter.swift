//
//  FirebaseAnalyticsEventConverter.swift
//  Tangem
//
//  Created by m3g0byt3 on 10.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Regex

/// See documentation for the `logEvent(_:parameters:)` method in `FIRAnalytics.h` for current Firebase Analytics limitations.
enum FirebaseAnalyticsEventConverter {
    /// The `\w` metacharacter matches word characters.
    /// A word character is a character a-z, A-Z, 0-9, including _ (underscore).
    private static let replacingPattern: StaticString = "[^\\w]"
    private static let trimmingCharacterSet = CharacterSet(charactersIn: "_")

    static func convert(event: String) -> String {
        return convert(string: event)
    }

    static func convert(params: [String: Any]) -> [String: Any] {
        return params.reduce(into: [:]) { result, element in
            let convertedKey = convert(string: element.key)
            let convertedValue = convert(value: element.value)
            result[convertedKey] = convertedValue
        }
    }

    private static func convert(string: String) -> String {
        return string
            .replacingAll(matching: replacingPattern, with: "_")
            .trimmingCharacters(in: trimmingCharacterSet)
            .trim(toLength: 40)
    }

    private static func convert(value: Any) -> Any {
        switch value {
        case let intValue as Int:
            return intValue
        case let doubleValue as Double:
            return doubleValue
        case let stringValue as String:
            return stringValue.trim(toLength: 100)
        default:
            return String(describing: value).trim(toLength: 100)
        }
    }
}

// MARK: - Convenience extensions

private extension String {
    func trim(toLength length: Int) -> String {
        String(prefix(length))
    }
}
