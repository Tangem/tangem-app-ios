//
//  AnyPublisher+.swift
//  TangemExpress
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
                .flatMap { output in
                    let subject = PassthroughSubject<Output, Failure>()

                    let task = Task(priority: priority) {
                        let mapped = await transform(output)
                        subject.send(mapped)
                        subject.send(completion: .finished)
                    }

                    return subject
                        .handleEvents(receiveCancel: { task.cancel() })
                        .eraseToAnyPublisher()
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
