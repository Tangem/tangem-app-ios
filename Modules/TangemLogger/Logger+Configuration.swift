//
//  Logger+Configuration.swift
//  TangemModules
//
//  Created by Sergey Balashov on 24.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Configuration

public extension Logger {
    protocol Configuration {
        func isLoggable() -> Bool
    }

    struct DefaultConfiguration: Configuration {
        public init() {}

        public func isLoggable() -> Bool { false }
    }
}

// MARK: - PrefixBuilder

public extension Logger {
    protocol Tagable {
        func tag(_ tag: String) -> Self
    }
}
