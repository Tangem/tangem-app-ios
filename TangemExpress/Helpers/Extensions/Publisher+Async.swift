//
//  Publisher+Async.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public extension Publisher {
    func async() async throws -> Output {
        var didSendValue = false
        let cancellableWrapper = CancellableWrapper()

        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                // This check is necessary in case this code runs after the task was
                // cancelled. In which case we want to bail right away.
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                cancellableWrapper.cancellable = first()
                    .handleEvents(receiveCancel: {
                        // We don't get a cancel error when cancelling a publisher, so we need
                        // to handle if the publisher was cancelled from the
                        // `withTaskCancellationHandler` here.
                        continuation.resume(throwing: CancellationError())
                    }).sink { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        } else if !didSendValue {
                            continuation.resume(throwing: AsyncError.valueWasNotEmittedBeforeCompletion)
                        }
                    } receiveValue: { value in
                        didSendValue = true
                        continuation.resume(with: .success(value))
                    }
            }
        } onCancel: {
            cancellableWrapper.cancellable?.cancel()
        }
    }
}

enum AsyncError: Error {
    case valueWasNotEmittedBeforeCompletion
}

private class CancellableWrapper {
    var cancellable: AnyCancellable?
}
