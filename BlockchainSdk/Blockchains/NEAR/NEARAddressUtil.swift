//
//  NEARAddressUtil.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// See https://nomicon.io/DataStructures/Account#account-id-rules for information about implicit/named account IDs.
enum NEARAddressUtil {
    static func isImplicitAccount(accountId: String) -> Bool {
        guard accountId.count == Constants.implicitAccountIdLength else {
            return false
        }

        return accountId.isLowercasedHexStringWithoutPrefix
    }

    /// - Warning: In theory, every valid implicit account ID is also a valid named account ID (but not vise-versa).
    /// Therefore, always check whether the account ID is implicit or not first, and only if it isn't,
    /// consider it a named account and check its validity.
    static func isValidNamedAccount(accountId: String) -> Bool {
        return accountId.count >= Constants.namedAccountIdMinLength
            && accountId.count <= Constants.namedAccountIdMaxLength
            && accountId.matches(Constants.namedAccountIdRegex)
            && accountId != Constants.systemAccountId
    }
}

// MARK: - Constants

private extension NEARAddressUtil {
    enum Constants {
        /// See https://nomicon.io/DataStructures/Account#system-account for details.
        static let systemAccountId = "system"
        static let implicitAccountIdLength = 64
        static let namedAccountIdMinLength = 2
        static let namedAccountIdMaxLength = implicitAccountIdLength
        static let namedAccountIdRegex = try! NSRegularExpression(
            pattern: "^(([a-z\\d]+[\\-_])*[a-z\\d]+\\.)*([a-z\\d]+[\\-_])*[a-z\\d]+$",
            options: .anchorsMatchLines
        )
    }
}

// MARK: - Convenience extensions

private extension String {
    /// 0 through 9.
    private static let asciiDecimalDigits: ClosedRange<UInt8> = UInt8(48) ... UInt8(57)

    /// a through f.
    private static let asciiLowercaseHexDigits: ClosedRange<UInt8> = UInt8(97) ... UInt8(102)

    var isLowercasedHexStringWithoutPrefix: Bool {
        return allSatisfy { character in
            guard character.isASCII else {
                return false
            }

            return Self.asciiDecimalDigits.contains(character.asciiValue!)
                || Self.asciiLowercaseHexDigits.contains(character.asciiValue!)
        }
    }

    func matches(_ regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: utf16.count)

        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
