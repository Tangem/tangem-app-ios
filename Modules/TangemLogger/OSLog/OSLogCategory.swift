//
//  OSLogCategory.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct OSLogCategory {
    public let name: String
    public let prefix: ((_ level: Logger.Level, _ option: Logger.PrefixOption) -> String)?

    public init(
        name: String,
        prefix: ((_: Logger.Level, _: Logger.PrefixOption) -> String)? = {
            PrefixBuilder().prefix(level: $0, option: $1)
        }
    ) {
        self.name = name
        self.prefix = prefix
    }
}

// MARK: Tagable

extension OSLogCategory: Logger.Tagable {
    public func tag(_ tag: String) -> Self {
        OSLogCategory(name: "\(name) [\(tag)]")
    }
}

// MARK: - Hashable

extension OSLogCategory: Hashable {
    public static func == (lhs: OSLogCategory, rhs: OSLogCategory) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// MARK: - PrefixBuilder

public extension OSLogCategory {
    struct PrefixBuilder {
        public init() {}
        public func prefix(level _: Logger.Level, option: Logger.PrefixOption) -> String {
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
