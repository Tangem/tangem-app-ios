//
//  AnyPublisher+.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 07.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
extension AnyPublisher where Failure: Error {
    static func just(output: Output) -> AnyPublisher<Output, Never> {
        Just(output).eraseToAnyPublisher()
    }

    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { output in
                    continuation.resume(returning: output)
                }
        }
    }
}

@available(*, deprecated, message: "Migrate to CombineExt if applicable (IOS-4000)")
extension AnyPublisher where Failure == Never {
    func async() async -> Output {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink { completion in
                    cancellable?.cancel()
                } receiveValue: { output in
                    continuation.resume(returning: output)
                }
        }
    }
}
