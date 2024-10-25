//
//  URLSessionWebSocketTaskWrapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// A wrapper to work with `URLSessionWebSocketTask` through async/await method
class URLSessionWebSocketTaskWrapper {
    private let url: URL

    private let webSocketTaskDidOpen = CheckedContinuationWrapper<Void, Error>(
        fallback: .failure(CancellationError())
    )

    private let webSocketTaskDidClose = CheckedContinuationWrapper<URLSessionWebSocketTask.CloseCode, Never>(
        fallback: .success(.abnormalClosure)
    )

    private var session: URLSession?
    private var _sessionWebSocketTask: URLSessionWebSocketTask?

    private var sessionWebSocketTask: URLSessionWebSocketTask {
        get throws {
            guard let _sessionWebSocketTask else {
                throw WebSocketTaskError.webSocketNotFound
            }

            return _sessionWebSocketTask
        }
    }

    init(url: URL) {
        self.url = url
    }

    deinit {
        // We have to disconnect here that release all objects
        cancel()
    }

    func sendPing() async throws {
        let socketTask = try sessionWebSocketTask

        return try await withCheckedThrowingContinuation { [weak socketTask] continuation in
            socketTask?.sendPing { error in
                switch error {
                case .none:
                    continuation.resume()
                case .some(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func send(message: URLSessionWebSocketTask.Message) async throws {
        try await sessionWebSocketTask.send(message)
    }

    func receive() async throws -> URLSessionWebSocketTask.Message {
        return try await sessionWebSocketTask.receive()
    }

    func connect() async throws {
        // The delegate will be kept by URLSession
        let delegate = URLSessionWebSocketDelegateWrapper(
            webSocketTaskDidOpen: { [weak self] _ in
                self?.webSocketTaskDidOpen.resume(with: .success(()))
            },
            webSocketTaskDidClose: { [weak self] _, closeCode in
                self?.webSocketTaskDidClose.resume(with: .success(closeCode))
            },
            webSocketTaskDidCompleteWithError: { [weak self] _, error in
                self?.cancel()

                if let error {
                    self?.webSocketTaskDidOpen.resume(with: .failure(error))
                }
            }
        )

        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        _sessionWebSocketTask = session?.webSocketTask(with: url)
        _sessionWebSocketTask?.resume()

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.webSocketTaskDidOpen.set(continuation)
        }
    }

    func cancel() {
        _sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        // Important for release of the session's delegate
        session?.invalidateAndCancel()
    }

    func cancel() async -> URLSessionWebSocketTask.CloseCode {
        _sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)

        return await withCheckedContinuation { [weak self] continuation in
            self?.webSocketTaskDidClose.set(continuation)
        }
    }
}

// MARK: - CustomStringConvertible

extension URLSessionWebSocketTaskWrapper: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Error

enum WebSocketTaskError: Error {
    case webSocketNotFound
}

// MARK: - Auxiliary types

private extension URLSessionWebSocketTaskWrapper {
    /// This lightweight wrapper ensures two things:
    /// - The wrapped continuation is resumed only once.
    /// - The wrapped continuation never leaks (by leaving unresumed).
    final class CheckedContinuationWrapper<T, E> where E: Error {
        private var continuation: CheckedContinuation<T, E>?
        private let fallback: () -> Result<T, E>
        private let criticalSection = Lock(isRecursive: false)

        init(fallback: @autoclosure @escaping () -> Result<T, E>) {
            self.fallback = fallback
        }

        deinit {
            set(nil)
        }

        func set(_ newContinuation: CheckedContinuation<T, E>?) {
            criticalSection {
                continuation?.resume(with: fallback())
                continuation = newContinuation
            }
        }

        func resume(with result: Result<T, E>) {
            criticalSection {
                continuation?.resume(with: result)
                continuation = nil
            }
        }
    }
}
