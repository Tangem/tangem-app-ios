//
//  Decimal+.swift
//  TangemFoundation
//
//  Created by Andrey Fedorov on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension Decimal {
    /// Parses given string using a fixed `en_US_POSIX` locale.
    /// - Note: Prefer this initializer to the `init?(string:locale:)` or `init?(_:)`.
    init?(stringValue: String?) {
        guard let stringValue = stringValue else {
            return nil
        }

        self.init(string: stringValue, locale: .posixEnUS)
    }
}
