//
//  SwiftConcurrency+.swift
//  TangemFoundation
//
//  Created by m3g0byt3 on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@discardableResult
public func runTask(isDetached: Bool = false, code: @escaping () -> Void) -> Task<Void, Never> {
    return isDetached ? Task.detached(operation: code) : Task(operation: code)
}

@discardableResult
public func runTask(isDetached: Bool = false, code: @escaping () async -> Void) -> Task<Void, Never> {
    return isDetached ? Task.detached(operation: code) : Task(operation: code)
}

@discardableResult
public func runTask(isDetached: Bool = false, code: @escaping () async throws -> Void) -> Task<Void, Error> {
    return isDetached ? Task.detached(operation: code) : Task(operation: code)
}

@discardableResult
public func runTask<T: AnyObject>(
    in object: T,
    isDetached: Bool = false,
    code: @escaping (_ input: T) async -> Void
) -> Task<Void, Never> {
    let operation = { [weak object] in
        guard let object else { return }

        await code(object)
    }

    return isDetached ? Task.detached(operation: operation) : Task(operation: operation)
}

@discardableResult
public func runTask<T: AnyObject>(
    in object: T,
    isDetached: Bool = false,
    code: @escaping (_ input: T) async throws -> Void
) -> Task<Void, Error> {
    let operation = { [weak object] in
        guard let object else { return }

        try await code(object)
    }

    return isDetached ? Task.detached(operation: operation) : Task(operation: operation)
}

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(abs(seconds)) * NSEC_PER_SEC
        try await Task.sleep(nanoseconds: duration)
    }
}

public extension Task where Failure == Error {
    static func delayed(
        withDelay delaySeconds: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            if delaySeconds > 0 {
                try await Task<Never, Never>.sleep(seconds: delaySeconds)
            }
            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}

public extension Task {
    func eraseToAnyCancellable() -> AnyCancellable {
        return AnyCancellable(cancel)
    }
}
