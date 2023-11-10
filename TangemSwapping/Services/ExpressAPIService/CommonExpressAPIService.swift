//
//  CommonExpressAPIService.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya

struct CommonExpressAPIService {
    private let provider: MoyaProvider<ExpressAPITarget>
    private let logger: SwappingLogger
    private let decoder = JSONDecoder()

    init(provider: MoyaProvider<ExpressAPITarget>, logger: SwappingLogger) {
        assert(
            provider.plugins.contains(where: { $0 is ExpressAuthorizationPlugin }),
            "Should contains ExpressHeaderMoyaPlugin"
        )

        self.provider = provider
        self.logger = logger
    }
}

extension CommonExpressAPIService: ExpressAPIService {
    func assets(request: ExpressDTO.Assets.Request) async throws -> [ExpressDTO.Assets.Response] {
        try await _request(target: .assets(request: request))
    }

    func pairs(request: ExpressDTO.Pairs.Request) async throws -> [ExpressDTO.Pairs.Response] {
        try await _request(target: .pairs(request: request))
    }

    func providers() async throws -> [ExpressDTO.Providers.Response] {
        try await _request(target: .providers)
    }

    func exchangeQuote(request: ExpressDTO.ExchangeQuote.Request) async throws -> ExpressDTO.ExchangeQuote.Response {
        try await _request(target: .exchangeQuote(request: request))
    }

    func exchangeData(request: ExpressDTO.ExchangeData.Request) async throws -> ExpressDTO.ExchangeData.Response {
        try await _request(target: .exchangeData(request: request))
    }

    func exchangeResult(request: ExpressDTO.ExchangeResult.Request) async throws -> ExpressDTO.ExchangeResult.Response {
        try await _request(target: .exchangeResult(request: request))
    }
}

private extension CommonExpressAPIService {
    func _request<T: Decodable>(target: ExpressAPITarget) async throws -> T {
        var response: Response

        do {
            response = try await provider.asyncRequest(target)
        } catch {
            logError(target: target, error: error)
            throw ExpressAPIServiceError.requestError(error)
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            try handleError(target: target, response: response)
        }

        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            logError(target: target, response: response, error: error)
            throw ExpressAPIServiceError.decodingError(error)
        }
    }

    func handleError(target: ExpressAPITarget, response: Response) throws {
        let decoder = JSONDecoder()

        do {
            let error = try decoder.decode(ExpressDTO.APIError.self, from: response.data)
            logError(target: target, response: response, error: error)
            throw ExpressAPIServiceError.apiError(error)
        } catch {
            logError(target: target, response: response, error: error)
            throw ExpressAPIServiceError.decodingError(error)
        }
    }

    func logError(target: TargetType, response: Response? = nil, error: Any) {
        var info = ""
        if let response {
            info = String(data: response.data, encoding: .utf8)!
        }

        logger.debug(
            """
            Error when request to target \(target.path)
            with info \(info)
            \(error)
            """
        )
    }
}
