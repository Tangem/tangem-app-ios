//
//  Publisher+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
extension Publisher {
    func withWeakCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.CompactMap<Self, (Object, Self.Output)> where Object: AnyObject {
        return compactMap { [weak object] output in
            guard let object = object else { return nil }

            return (object, output)
        }
    }

    func mapToVoid() -> Publishers.Map<Self, Void> {
        map { _ in () }
    }

    func mapToResult() -> some Publisher<Result<Self.Output, Self.Failure>, Never> {
        return map(Result.success)
            .catch { Just(Result.failure($0)) }
    }
}

extension Publisher where Failure == Swift.Error {
    func asyncMap<T>(
        priority: TaskPriority? = nil,
        _ transform: @escaping (_ input: Self.Output) async throws -> T
    ) -> some Publisher<T, Self.Failure> {
        return Publishers.AsyncMap(upstream: self, priority: priority, transform: transform)
    }
}

extension Publisher {
    func handleEvents(
        receiveSubscription: ((Subscription) -> Void)? = nil,
        receiveOutput: ((Self.Output) -> Void)? = nil,
        receiveFailure: ((Self.Failure) -> Void)? = nil,
        receiveFinish: (() -> Void)? = nil,
        receiveCancel: (() -> Void)? = nil,
        receiveRequest: ((Subscribers.Demand) -> Void)? = nil
    ) -> Publishers.HandleEvents<Self> {
        return handleEvents(
            receiveSubscription: receiveSubscription,
            receiveOutput: receiveOutput,
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receiveFinish?()
                case .failure(let error):
                    receiveFailure?(error)
                }
            },
            receiveCancel: receiveCancel,
            receiveRequest: receiveRequest
        )
    }
}

extension Publisher {
    static var emptyFail: AnyPublisher<Output, Error> {
        return Fail(error: WalletError.empty)
            .eraseToAnyPublisher()
    }

    static func anyFail(error: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: error)
            .eraseToAnyPublisher()
    }

    static func sendTxFail(error: Error) -> AnyPublisher<Output, SendTxError> {
        return Fail(error: SendTxError(error: error))
            .eraseToAnyPublisher()
    }

    static func justWithError(output: Output) -> AnyPublisher<Output, Error> {
        return Just(output)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    static func multiAddressPublisher<T>(
        addresses: [String],
        requestFactory: (String) -> AnyPublisher<T, Error>
    ) -> AnyPublisher<[T], Error> {
        return Publishers
            .MergeMany(addresses.map { requestFactory($0) })
            .collect()
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Error {
    /*
     This method is used to override a network error when sending a transaction.
     Use only pair with send method for {{Blockchain}}NetworkService.
     */
    public func mapSendError(tx: String? = nil) -> Publishers.MapError<Self, Error> {
        mapError { error in
            SendTxErrorFactory().make(error: error, with: tx)
        }
    }

    /*
     This method is used to override a network error when sending a transaction after all chains publishers.
     */
    func eraseSendError() -> Publishers.MapError<Self, SendTxError> {
        mapError { error in
            SendTxErrorFactory().make(error: error)
        }
    }
}

// MARK: - Private implementation

private extension Publishers {
    struct AsyncMap<Upstream, Output>: Publisher where Upstream: Publisher, Upstream.Failure == Swift.Error {
        typealias Output = Output
        typealias Failure = Upstream.Failure
        typealias Transform = (_ input: Upstream.Output) async throws -> Output

        let upstream: Upstream
        let priority: TaskPriority?
        let transform: Transform

        init(upstream: Upstream, priority: TaskPriority?, transform: @escaping Transform) {
            self.upstream = upstream
            self.priority = priority
            self.transform = transform
        }

        func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Self.Output == S.Input {
            upstream
                .flatMap { output in
                    let subject = PassthroughSubject<Output, Failure>()

                    let task = Task(priority: priority) {
                        do {
                            let mapped = try await transform(output)
                            subject.send(mapped)
                            subject.send(completion: .finished)
                        } catch {
                            subject.send(completion: .failure(error))
                        }
                    }

                    return subject.handleEvents(receiveCancel: task.cancel)
                }
                .receive(subscriber: subscriber)
        }
    }
}
