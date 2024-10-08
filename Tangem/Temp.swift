//
//  Temp.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

@available(*, deprecated, message: "Test only, remove")
extension Moya.Task {
    static func requestParameters(
        _ encodable: Encodable,
        encoder: JSONEncoder = JSONEncoder(),
        encoding: ParameterEncoding = Moya.URLEncoding()
    ) -> Task {
        do {
            let data = try encoder.encode(encodable)
            let parameters = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return .requestParameters(parameters: parameters ?? [:], encoding: encoding)
        } catch {
            assertionFailure("Moya.Task request parameters catch error \(error)")
            return .requestPlain
        }
    }
}

@available(*, deprecated, message: "Test only, remove")
extension MoyaProvider {
    func asyncRequest(_ target: Target) async throws -> Response {
        let asyncRequestWrapper = AsyncMoyaRequestWrapper<Response> { [weak self] continuation in
            return self?.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                asyncRequestWrapper.perform(continuation: continuation)
            }
        } onCancel: {
            asyncRequestWrapper.cancel()
        }
    }
}

private class AsyncMoyaRequestWrapper<T> {
    typealias MoyaContinuation = CheckedContinuation<T, Error>

    var performRequest: (MoyaContinuation) -> Moya.Cancellable?
    var cancellable: Moya.Cancellable?

    init(_ performRequest: @escaping (MoyaContinuation) -> Moya.Cancellable?) {
        self.performRequest = performRequest
    }

    func perform(continuation: MoyaContinuation) {
        cancellable = performRequest(continuation)
    }

    func cancel() {
        cancellable?.cancel()
    }
}
