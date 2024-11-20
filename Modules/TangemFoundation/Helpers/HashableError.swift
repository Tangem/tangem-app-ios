//
//  HashableError.swift
//  TangemModules
//
//  Created by Sergey Balashov on 20.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct HashableError: LocalizedError {
    public let error: Swift.Error

    public init(error: Error) {
        self.error = error
    }
}

// MARK: - Hashable

extension HashableError: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(error.localizedDescription)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - CustomStringConvertible

extension HashableError: CustomStringConvertible {
    public var description: String {
        error.localizedDescription
    }
}

// MARK: - Error+

public extension Error {
    func asHashable() -> HashableError {
        HashableError(error: self)
    }
}
