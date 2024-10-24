//
//  Publisher+Async.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 07.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

public extension Publisher {
    func async() async throws -> Output {
        let cancellableWrapper = CancellableWrapper()

        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let continuationWrapper = CheckedContinuationWrapper(continuation: continuation)

                // This check is necessary in case this code runs after the task was
                // cancelled. In which case we want to bail right away.
                guard !Task.isCancelled else {
                    continuationWrapper.resumeIfNeeded(throwing: CancellationError())
                    return
                }

                cancellableWrapper.value = first()
                    .handleEvents(receiveCancel: {
                        // We don't get a cancel error when cancelling a publisher, so we need
                        // to handle if the publisher was cancelled from the
                        // `withTaskCancellationHandler` here.
                        continuationWrapper.resumeIfNeeded(throwing: CancellationError())
                    })
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuationWrapper.resumeIfNeeded(throwing: AsyncError.valueWasNotEmittedBeforeCompletion)
                            case .failure(let error):
                                continuationWrapper.resumeIfNeeded(throwing: error)
                            }
                        },
                        receiveValue: { value in
                            continuationWrapper.resumeIfNeeded(returning: value)
                        }
                    )
            }
        } onCancel: {
            cancellableWrapper.cancel()
        }
    }
}

enum AsyncError: Error {
    case valueWasNotEmittedBeforeCompletion
}

/// Closures in `withTaskCancellationHandler(handler:operation:)` may be called on different threads,
/// this wrapper provides required synchronization.
private final class CancellableWrapper {
    var value: Cancellable? {
        get { criticalSection { innerCancellable } }
        set { criticalSection { innerCancellable = newValue } }
    }

    private var innerCancellable: Cancellable?
    private let criticalSection = Lock(isRecursive: false)

    func cancel() {
        criticalSection { innerCancellable?.cancel() }
    }
}

/// Resumes the given continuation exactly once.
private final class CheckedContinuationWrapper<T, E> where E: Error {
    private var wasResumed = false
    private let continuation: CheckedContinuation<T, E>
    private let criticalSection = Lock(isRecursive: false)

    init(continuation: CheckedContinuation<T, E>) {
        self.continuation = continuation
    }

    /// Safe shim for `CheckedContinuation.resume(returning:)`.
    func resumeIfNeeded(returning value: T) {
        criticalSection {
            if !wasResumed {
                wasResumed = true
                continuation.resume(returning: value)
            }
        }
    }

    /// Safe shim for `CheckedContinuation.resume(throwing:)`.
    func resumeIfNeeded(throwing error: E) {
        criticalSection {
            if !wasResumed {
                wasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }
}
