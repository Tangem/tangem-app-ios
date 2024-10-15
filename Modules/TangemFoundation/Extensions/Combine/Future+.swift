//
//  Future+.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 14.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Future where Failure == Error {
    static func async(operation: @escaping () async throws -> Output) -> some Publisher<Output, Failure> {
        var task: Task<Void, Failure>?

        return Future<Output, Failure> { promise in
            task = Task {
                do {
                    let output = try await operation()
                    try Task.checkCancellation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }.handleEvents(receiveCancel: {
            task?.cancel()
        })
    }
}
