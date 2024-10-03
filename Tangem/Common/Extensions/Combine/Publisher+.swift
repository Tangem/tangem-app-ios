//
//  Publisher+.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.04.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

extension Publisher where Output: Equatable {
    var uiPublisher: AnyPublisher<Output, Failure> {
        dropFirst()
            .debounce(for: 0.6, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var uiPublisherWithFirst: AnyPublisher<Output, Failure> {
        debounce(for: 0.6, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

public extension Publisher {
    /// Subscribes to current publisher without handling events
    func sink() -> AnyCancellable {
        return sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    /// An overload of the default `sink` method with the only `receiveValue` required closure.
    func receiveValue(_ receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }

    /// An overload of the default `sink` method with the only `receiveCompletion` required closure.
    func receiveCompletion(_ receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: receiveCompletion, receiveValue: { _ in })
    }

    func eraseError() -> AnyPublisher<Output, Error> {
        return mapError { error -> Error in
            return error as Error
        }
        .eraseToAnyPublisher()
    }

    static func anyFail(error: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: error)
            .eraseToAnyPublisher()
    }

    static func justWithError(output: Output) -> AnyPublisher<Output, Error> {
        return Just(output)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void, Failure == Error {
    static var just: AnyPublisher<Output, Failure> {
        Just(()).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void, Failure == Never {
    static var just: AnyPublisher<Output, Failure> {
        .just(output: ())
    }
}

@available(iOS, deprecated: 15.0, message: "AsyncCompatibilityKit is only useful when targeting iOS versions earlier than 15")
public extension Publisher where Failure == Never {
    /// Convert this publisher into an `AsyncStream` that can
    /// be iterated over asynchronously using `for await`. The
    /// stream will yield each output value produced by the
    /// publisher and will finish once the publisher completes.
    var values: AsyncStream<Output> {
        get async {
            AsyncStream { continuation in
                var cancellable: AnyCancellable?
                let onTermination = { cancellable?.cancel() }

                continuation.onTermination = { @Sendable _ in
                    onTermination()
                }

                cancellable = sink(
                    receiveCompletion: { _ in
                        continuation.finish()
                    }, receiveValue: { value in
                        continuation.yield(value)
                    }
                )
            }
        }
    }
}

extension Publisher {
    func withWeakCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.CompactMap<Self, (Object, Self.Output)> where Object: AnyObject {
        return compactMap { [weak object] output in
            guard let object = object else { return nil }

            return (object, output)
        }
    }

    func withUnownedCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.Map<Self, (Object, Self.Output)> where Object: AnyObject {
        return map { [unowned object] output in
            return (object, output)
        }
    }
}

extension Publisher {
    /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is optional.
    /// The first time the upstream publisher emits an element, the previous element will be `nil`.
    ///
    ///     let range = (1...5)
    ///     cancellable = range.publisher
    ///         .withPrevious()
    ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
    ///      // Prints: "(nil, 1) (Optional(1), 2) (Optional(2), 3) (Optional(3), 4) (Optional(4), 5) ".
    ///
    /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
    func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
        scan((Output?, Output)?.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is not optional.
    /// The first time the upstream publisher emits an element, the previous element will be the `initialPreviousValue`.
    ///
    ///     let range = (1...5)
    ///     cancellable = range.publisher
    ///         .withPrevious(0)
    ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
    ///      // Prints: "(0, 1) (1, 2) (2, 3) (3, 4) (4, 5) ".
    ///
    /// - Parameter initialPreviousValue: The initial value to use as the "previous" value when the upstream publisher emits for the first time.
    /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
    func withPrevious(_ initialPreviousValue: Output) -> AnyPublisher<(previous: Output, current: Output), Failure> {
        scan((initialPreviousValue, initialPreviousValue)) { ($0.1, $1) }.eraseToAnyPublisher()
    }
}

extension Publisher {
    func eraseToOptional() -> Publishers.Map<Self, Self.Output?> {
        map(Optional.some)
    }
}
