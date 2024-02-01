//
//  CommonExpressAPIService.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya

struct CommonExpressAPIService {
    private let provider: MoyaProvider<ExpressAPITarget>
    private let expressAPIType: ExpressAPIType
    private let logger: Logger
    private let decoder = JSONDecoder()

    init(provider: MoyaProvider<ExpressAPITarget>, expressAPIType: ExpressAPIType, logger: Logger) {
        assert(
            provider.plugins.contains(where: { $0 is ExpressAuthorizationPlugin }),
            "Should contains ExpressHeaderMoyaPlugin"
        )

        self.provider = provider
        self.expressAPIType = expressAPIType
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

    func exchangeStatus(request: ExpressDTO.ExchangeStatus.Request) async throws -> ExpressDTO.ExchangeStatus.Response {
        try await _request(target: .exchangeStatus(request: request))
    }
}

private extension CommonExpressAPIService {
    func _request<T: Decodable>(target: ExpressAPITarget.Target) async throws -> T {
        let request = ExpressAPITarget(expressAPIType: expressAPIType, target: target)
        var response: Response

        do {
            response = try await provider.asyncRequest(request)
        } catch {
            log(target: request, error: error)
            throw error
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
            log(target: request, response: response)
        } catch {
            if let expressError = tryMapError(target: request, response: response) {
                throw expressError
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

    func tryMapError(target: ExpressAPITarget, response: Response) -> ExpressAPIError? {
        do {
            let error = try JSONDecoder().decode(ExpressDTO.APIError.Response.self, from: response.data)
            log(target: target, response: response, error: error.error)
            return error.error
        } catch {
            log(target: target, response: response, error: error)
            return nil
        }
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
            task: \(target.task)
            ended with response: \(info)
            Error: \(String(describing: error))
            """
        )
    }
}
