//
//  LoadingResult.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 21.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// LoadingResult to wrap the loading process
/// Can be used in two ways
/// - `LoadingResult<Value, Never>` with two possible option `loading` and `value`
/// - `LoadingResult<Value, Error>` with three possible option `loading` / `value` / `error`
public enum LoadingResult<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    case loading
}

// MARK: - Initialization

public extension LoadingResult {
    static func result(_ result: Result<Success, Failure>) -> LoadingResult {
        switch result {
        case .success(let value): .success(value)
        case .failure(let error): .failure(error)
        }
    }
}

// MARK: - Calculated

public extension LoadingResult {
    var isLoading: Bool {
        switch self {
        case .loading: true
        case .success, .failure: false
        }
    }

    var value: Success? {
        switch self {
        case .success(let value): value
        case .loading, .failure: nil
        }
    }

    var error: Failure? {
        switch self {
        case .failure(let error): error
        case .loading, .success: nil
        }
    }

    func get() throws -> Success {
        switch self {
        case .success(let success): return success
        case .failure(let failure): throw failure
        case .loading: throw LoadingResultError.loadingInProcess
        }
    }
}

// MARK: - Equatable

extension LoadingResult: Equatable where Success: Equatable, Failure: Equatable {}

// MARK: - Hashable

extension LoadingResult: Hashable where Success: Hashable, Failure: Hashable {}

// MARK: - Mapping

public extension LoadingResult {
    func mapValue<T>(_ transform: (Success) throws -> T) rethrows -> LoadingResult<T, Failure> {
        switch self {
        case .loading: .loading
        case .success(let value): .success(try transform(value))
        case .failure(let error): .failure(error)
        }
    }
}

// MARK: - Error

public enum LoadingResultError: LocalizedError {
    case loadingInProcess

    public var errorDescription: String? {
        switch self {
        case .loadingInProcess: "Loading in process"
        }
    }
}
