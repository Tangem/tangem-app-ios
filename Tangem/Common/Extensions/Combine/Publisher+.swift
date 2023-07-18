//
//  Publisher+.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.04.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
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

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
extension Publisher where Failure == Never {
    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }

    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }

    func weakAssignAnimated<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
        sink { [weak root] value in
            withAnimation {
                root?[keyPath: keyPath] = value
            }
        }
    }

    func weakAssignAnimated<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on root: Root) -> AnyCancellable {
        sink { [weak root] value in
            withAnimation {
                root?[keyPath: keyPath] = value
            }
        }
    }
}

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
public extension Publisher {
    /// Subscribes to current publisher without handling events
    func sink() -> AnyCancellable {
        return sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }

    /// `receiveValue` clouser from default `sink` method
    func receiveValue(_ receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }

    /// `receiveCompletion` clouser from default `sink` method
    func receiveCompletion(_ receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: receiveCompletion, receiveValue: { _ in })
    }

    /// Transforms any received value to Void
    func mapVoid() -> Publishers.Map<Self, Void> {
        map { _ in }
    }

    func eraseError() -> AnyPublisher<Output, Error> {
        return mapError { error -> Error in
            return error as Error
        }
        .eraseToAnyPublisher()
    }
}

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
extension Publisher where Output == Void, Failure == Error {
    static var just: AnyPublisher<Output, Failure> {
        Just(()).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }
}

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
extension Publisher where Output == Void, Failure == Never {
    static var just: AnyPublisher<Output, Failure> {
        Just(()).eraseToAnyPublisher()
    }
}

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }

    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
}

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
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
