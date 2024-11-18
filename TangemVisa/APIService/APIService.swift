//
//  APIService.swift
//  TangemVisa
//
//  Created by Andrew Son on 05.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct APIService<Target: TargetType, ErrorType: Error & Decodable> {
    private let provider: MoyaProvider<Target>
    private let logger: InternalLogger
    private var decoder: JSONDecoder

    init(
        provider: MoyaProvider<Target>,
        logger: InternalLogger,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.logger = logger
        self.decoder = decoder
    }

    func request<T: Decodable>(_ request: Target) async throws -> T {
        var response: Response
        do {
            response = try await provider.asyncRequest(request)
        } catch {
            log(target: request, response: nil, error: error)
            throw error
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
            log(target: request, response: response, error: nil)
        } catch {
            if let apiError = tryMapError(target: request, response: response) {
                throw apiError
            }

            throw error
        }

        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            log(target: request, response: response, error: error)
            throw error
        }
    }

    func tryMapError(target: Target, response: Response) -> ErrorType? {
        do {
            let error = try JSONDecoder().decode(ErrorType.self, from: response.data)
            log(target: target, response: response, error: error)
            return error
        } catch {
            log(target: target, response: response, error: error)
            return nil
        }
    }

    func log(target: Target, response: Response?, error: Error?) {
        var info = ""
        if let response {
            info = String(data: response.data, encoding: .utf8)!
        }

        logger.debug(
            subsystem: .apiService,
            """
            Request target: \(target.path)
            Task: \(target.task)
            Response: \(info)
            Error: \(String(describing: error))
            """
        )
    }
}
