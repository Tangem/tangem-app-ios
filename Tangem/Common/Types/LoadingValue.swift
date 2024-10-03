//
//  LoadingValue.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Enum to wrap a value loading process
enum LoadingValue<Value> {
    case loading
    case loaded(_ value: Value)
    case failedToLoad(error: Error)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var value: Value? {
        if case .loaded(let value) = self {
            return value
        }

        return nil
    }

    var error: Error? {
        if case .failedToLoad(let error) = self {
            return error
        }

        return nil
    }
}

// MARK: - Equatable

extension LoadingValue: Equatable where Value: Equatable {
    static func == (lhs: LoadingValue<Value>, rhs: LoadingValue<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded(let lhs), .loaded(let rhs)):
            return lhs == rhs
        case (.failedToLoad(let lhs), .failedToLoad(let rhs)):
            return lhs.localizedDescription == rhs.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Hashable

extension LoadingValue: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .loading:
            hasher.combine("loading")
        case .loaded(let value):
            hasher.combine(value)
        case .failedToLoad(let error):
            hasher.combine(error.localizedDescription)
        }
    }
}

// MARK: - Hashable

extension LoadingValue {
    public func mapValue<T>(_ transform: (Value) throws -> T) rethrows -> LoadingValue<T> {
        switch self {
        case .loading: .loading
        case .loaded(let value): .loaded(try transform(value))
        case .failedToLoad(let error): .failedToLoad(error: error)
        }
    }
}
