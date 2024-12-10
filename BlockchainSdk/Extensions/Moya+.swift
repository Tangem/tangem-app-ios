//
//  Moya+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import struct AnyCodable.AnyEncodable

extension Moya.Task {
    static func requestJSONRPC(
        id: Int,
        method: String,
        params: Encodable?,
        encoder: JSONEncoder? = nil
    ) -> Self {
        let jsonRPCParams = JSONRPC.Request(
            jsonrpc: .v2,
            id: id,
            method: method,
            params: params.map(AnyEncodable.init)
        )

        if let encoder = encoder {
            return .requestCustomJSONEncodable(jsonRPCParams, encoder: encoder)
        }

        return .requestJSONEncodable(jsonRPCParams)
    }
}

extension Moya.URLEncoding {
    static var tangem: Self {
        let queryStringEncoding: URLEncoding = .queryString

        return URLEncoding(
            destination: queryStringEncoding.destination,
            arrayEncoding: queryStringEncoding.arrayEncoding,
            boolEncoding: .literal
        )
    }
}

extension Moya.Response {
    func tryMap<Output, Failure>(
        output: Output.Type,
        failure: Failure.Type,
        using decoder: JSONDecoder = JSONDecoder(),
        failsOnEmptyData: Bool = true
    ) throws -> Output where Output: Decodable, Failure: Decodable, Failure: Error {
        if let apiError = try? map(failure, using: decoder, failsOnEmptyData: failsOnEmptyData) {
            throw apiError
        }

        return try map(output, using: decoder, failsOnEmptyData: failsOnEmptyData)
    }
}

extension MoyaProvider {
    func asyncRequest(for target: Target) async throws -> Response {
        let cancellableWrapper = CancellableWrapper()

        return try await withTaskCancellationHandler(
            operation: { [weak self] in
                return try await withCheckedThrowingContinuation { continuation in
                    // This check is required since `operation` closure is called regardless of whether the task is cancelled or not
                    if _Concurrency.Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    cancellableWrapper.value = self?.request(target) { result in
                        switch result {
                        case .success(let responseValue):
                            continuation.resume(returning: responseValue)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            },
            onCancel: {
                cancellableWrapper.cancel()
            }
        )
    }

    /// Get cached response for provided target.
    /// Limited to targets which provide the same URLRequest on different calls.
    /// - Parameter target: request target
    /// - Returns: response from urlCache
    public func cachedResponse(for target: Target) -> CachedURLResponse? {
        let endpoint = endpoint(target)
        guard let urlRequest = try? endpoint.urlRequest() else { return nil }
        return session.session.configuration.urlCache?.cachedResponse(for: urlRequest)
    }
}

// MARK: - Auxiliary types

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
