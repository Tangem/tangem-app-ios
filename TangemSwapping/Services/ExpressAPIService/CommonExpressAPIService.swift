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
            log(target: target, error: error)
            throw error
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
            log(target: target, response: response)
        } catch {
            try handleError(target: target, response: response)
        }

        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            log(target: target, response: response, error: error)
            throw error
        }
    }

    func handleError(target: ExpressAPITarget, response: Response) throws {
        let decoder = JSONDecoder()

        let error = try decoder.decode(ExpressDTO.APIError.Response.self, from: response.data)
        log(target: target, response: response, error: error.error)
        throw error.error
    }

    func log(target: TargetType, response: Response? = nil, error: Error? = nil) {
        var info = ""
        if let response {
            info = String(data: response.data, encoding: .utf8)!
        }

        logger.debug(
            """
            [ExpressAPIService]
            Request to target: \(target.path)
            plugins: \(provider.plugins))
            task: \(target.task)
            eded with response: \(info)
            Error: \(String(describing: error))
            """
        )
    }
}
