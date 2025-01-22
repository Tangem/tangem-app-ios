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
        func shouldPrint(category: Category, level: Level) -> Bool
        func shouldStore(category: Category, level: Level) -> Bool
    }

    struct DefaultConfiguration: Configuration {
        public init() {}

        public func shouldPrint(category: Category, level: Level) -> Bool { false }
        public func shouldStore(category: Category, level: Level) -> Bool { false }
    }
}

// MARK: - PrefixBuilder

public extension Logger {
    protocol PrefixBuilder {
        func prefix(category: Category, level: Level, option: PrefixOption) -> String?
    }

    struct DefaultPrefixBuilder: PrefixBuilder {
        public init() {}

        public func prefix(category _: Category, level _: Level, option: Logger.PrefixOption) -> String? {
            switch option {
            case .object(.none):
                return "<EmptyObject>"
            case .object(.some(let object)):
                return "\(object.description)"
            case .verbose(let file, let line, let function):
                let prefix = "\(URL(fileURLWithPath: file.description).deletingPathExtension().lastPathComponent):\(line):\(function)"
                return "<\(prefix)>"
            }
        }
    }
}
