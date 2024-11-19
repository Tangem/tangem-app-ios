//
//  Publisher+AsyncMap.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 13.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Publishers {
    struct AsyncMap<Upstream, Output>: Publisher where Upstream: Publisher, Upstream.Failure == Never {
        public typealias Failure = Upstream.Failure

        public let upstream: Upstream
        public let priority: TaskPriority?
        public let transform: (Upstream.Output) async -> Output

        public init(upstream: Upstream, priority: TaskPriority?, transform: @escaping (Upstream.Output) async -> Output) {
            self.upstream = upstream
            self.priority = priority
            self.transform = transform
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Output == S.Input {
            upstream
                .flatMap { value in
                    var task: Task<Void, Never>? = nil

                    let future = Deferred {
                        Future<Output, Never> { promise in
                            task = Task(priority: priority) {
                                guard !Task.isCancelled else { return }

                                let output = await transform(value)

                                guard !Task.isCancelled else { return }

                                promise(.success(output))
                            }
                        }
                    }

                    return future.handleEvents(receiveCancel: task?.cancel)
                }
                .receive(subscriber: subscriber)
        }
    }
}

public extension Publisher where Failure == Never {
    func asyncMap<T>(priority: TaskPriority? = .none, _ transform: @escaping (Output) async -> T) -> Publishers.AsyncMap<Self, T> {
        .init(upstream: self, priority: priority, transform: transform)
    }
}
