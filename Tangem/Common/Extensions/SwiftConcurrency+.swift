//
//  SwiftConcurrency+.swift
//  Tangem
//
//  Created by Andrew Son on 18/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import class Combine.AnyCancellable

@available(*, deprecated, message: "Use equivalent helpers from 'TangemFoundation' module instead")
@discardableResult
func runTask(_ code: @escaping () async -> Void) -> Task<Void, Never> {
    Task {
        await code()
    }
}

@available(*, deprecated, message: "Use equivalent helpers from 'TangemFoundation' module instead")
@discardableResult
func runTask(_ code: @escaping () async throws -> Void) -> Task<Void, Error> {
    Task {
        try await code()
    }
}

@available(*, deprecated, message: "Use equivalent helpers from 'TangemFoundation' module instead")
@discardableResult
func runTask(_ code: @escaping () -> Void) -> Task<Void, Never> {
    Task {
        code()
    }
}

@available(*, deprecated, message: "Use equivalent helpers from 'TangemFoundation' module instead")
@discardableResult
func runTask<T: AnyObject>(in object: T, code: @escaping (T) async throws -> Void) -> Task<Void, Error> {
    Task { [weak object] in
        guard let object else { return }

        try await code(object)
    }
}

@available(*, deprecated, message: "Use equivalent helpers from 'TangemFoundation' module instead")
@discardableResult
func runTask<T: AnyObject>(in object: T, code: @escaping (T) async -> Void) -> Task<Void, Never> {
    Task { [weak object] in
        guard let object else { return }

        await code(object)
    }
}

func runInTask<T>(_ code: @escaping () async throws -> T) async throws -> T {
    try await Task<T, Error> {
        try await code()
    }.value
}

func runInTask<T>(_ code: @escaping () async -> T) async throws -> T {
    try await Task<T, Error> {
        await code()
    }.value
}

@discardableResult
@MainActor
func runOnMain<T>(_ code: () throws -> T) rethrows -> T {
    return try code()
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(abs(seconds)) * NSEC_PER_SEC
        try await Task.sleep(nanoseconds: duration)
    }
}

extension Task {
    func store(in container: inout Set<Self>) {
        container.insert(self)
    }
}

@discardableResult
func runTask<T>(withTimeout timeout: TimeInterval, _ code: @escaping () async -> T, onTimeout: @escaping () -> Void = {}) -> Task<T, Error> {
    Task.detached {
        do {
            return try await runTask(withTimeout: timeout, code)
        } catch let taskError as TaskError {
            switch taskError {
            case .timeout:
                onTimeout()
            }

            throw taskError
        } catch {
            throw error
        }
    }
}

func runTask<T>(withTimeout timeout: TimeInterval, _ code: @escaping () async -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            await code()
        }

        group.addTask {
            try await Task.sleepCancellable(forSeconds: timeout)

            try Task.checkCancellation()
            throw TaskError.timeout
        }

        // We can safely force-unwrap, because `group.next()` can return nil only when tasks weren't added to the group
        // Group will receive the first finished result, even if group schedules waiting for the next result after the first
        // task or all tasks execution finished.
        let result: T = try await group.next()!
        group.cancelAll()

        return result
    }
}

enum TaskError: Error {
    case timeout
}

extension Task where Success == Never, Failure == Never {
    static var defaultCancellationCheckInterval: TimeInterval { 0.1 }

    /// Like `Task.sleep` but with cancellation support.
    ///
    /// - Parameter seconds: Sleep this number of seconds. The actual time the sleep ends can be later.
    /// - Parameter cancellationCheckInterval: The interval in seconds between cancellation checks.
    static func sleepCancellable(forSeconds seconds: TimeInterval, cancellationCheckInterval: TimeInterval = defaultCancellationCheckInterval) async throws {
        try await sleepCancellable(until: Date().addingTimeInterval(seconds), cancellationCheckInterval: cancellationCheckInterval)
    }

    /// Like `Task.sleep` but with cancellation support.
    ///
    /// - Parameter deadline: Sleep at least until this time. The actual time the sleep ends can be later.
    /// - Parameter cancellationCheckInterval: The interval in seconds between cancellation checks.
    static func sleepCancellable(until deadline: Date, cancellationCheckInterval: TimeInterval = defaultCancellationCheckInterval) async throws {
        let cancellationCheckIntervalUint64 = UInt64(cancellationCheckInterval) * NSEC_PER_SEC
        while Date() < deadline {
            if Task.isCancelled {
                break
            }
            // Sleep for a while between cancellation checks.
            try await Task.sleep(nanoseconds: cancellationCheckIntervalUint64)
        }
    }
}

extension Task {
    func eraseToAnyCancellable() -> AnyCancellable {
        return AnyCancellable(cancel)
    }
}
