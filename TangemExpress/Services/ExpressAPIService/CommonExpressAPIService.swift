//
//  CommonExpressAPIService.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya
import TangemFoundation

struct CommonExpressAPIService {
    private let provider: MoyaProvider<ExpressAPITarget>
    private let expressAPIType: ExpressAPIType
    private let decoder = JSONDecoder()

    init(provider: MoyaProvider<ExpressAPITarget>, expressAPIType: ExpressAPIType) {
        assert(
            provider.plugins.contains(where: { $0 is ExpressAuthorizationPlugin }),
            "Should contains ExpressHeaderMoyaPlugin"
        )

        self.provider = provider
        self.expressAPIType = expressAPIType
    }
}

// MARK: - ExpressAPIService

extension CommonExpressAPIService: ExpressAPIService {
    // MARK: - Swap

    func assets(request: ExpressDTO.Swap.Assets.Request) async throws -> [ExpressDTO.Swap.Assets.Response] {
        try await _request(target: .assets(request: request))
    }

    func pairs(request: ExpressDTO.Swap.Pairs.Request) async throws -> [ExpressDTO.Swap.Pairs.Response] {
        try await _request(target: .pairs(request: request))
    }

    func providers() async throws -> [ExpressDTO.Swap.Providers.Response] {
        try await _request(target: .providers)
    }

    func exchangeQuote(request: ExpressDTO.Swap.ExchangeQuote.Request) async throws -> ExpressDTO.Swap.ExchangeQuote.Response {
        try await _request(target: .exchangeQuote(request: request))
    }

    func exchangeData(request: ExpressDTO.Swap.ExchangeData.Request) async throws -> ExpressDTO.Swap.ExchangeData.Response {
        try await _request(target: .exchangeData(request: request))
    }

    func exchangeStatus(request: ExpressDTO.Swap.ExchangeStatus.Request) async throws -> ExpressDTO.Swap.ExchangeStatus.Response {
        try await _request(target: .exchangeStatus(request: request))
    }

    func exchangeSent(request: ExpressDTO.Swap.ExchangeSent.Request) async throws -> ExpressDTO.Swap.ExchangeSent.Response {
        try await _request(target: .exchangeSent(request: request))
    }

    // MARK: - Onramp

    func onrampCurrencies() async throws -> [ExpressDTO.Onramp.FiatCurrency] {
        try await _request(target: .onrampCurrencies)
    }

    func onrampCountries() async throws -> [ExpressDTO.Onramp.Country] {
        try await _request(target: .onrampCountries)
    }

    func onrampCountryByIP() async throws -> ExpressDTO.Onramp.Country {
        try await _request(target: .onrampCountryByIP)
    }

    func onrampPaymentMethods() async throws -> [ExpressDTO.Onramp.PaymentMethod] {
        try await _request(target: .onrampPaymentMethods)
    }

    func onrampPairs(request: ExpressDTO.Onramp.Pairs.Request) async throws -> [ExpressDTO.Onramp.Pairs.Response] {
        try await _request(target: .onrampPairs(request: request))
    }

    func onrampQuote(request: ExpressDTO.Onramp.Quote.Request) async throws -> ExpressDTO.Onramp.Quote.Response {
        try await _request(target: .onrampQuote(request: request))
    }

    func onrampData(request: ExpressDTO.Onramp.Data.Request) async throws -> ExpressDTO.Onramp.Data.Response {
        try await _request(target: .onrampData(request: request))
    }

    func onrampStatus(request: ExpressDTO.Onramp.Status.Request) async throws -> ExpressDTO.Onramp.Status.Response {
        try await _request(target: .onrampStatus(request: request))
    }
}

private extension CommonExpressAPIService {
    func _request<T: Decodable>(target: ExpressAPITarget.Target) async throws -> T {
        let request = ExpressAPITarget(expressAPIType: expressAPIType, target: target)
        var response: Response

        response = try await provider.requestPublisher(request).async()

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            if let expressError = tryMapError(target: request, response: response) {
                throw expressError
            }

            throw error
        }

        return try decoder.decode(T.self, from: response.data)
    }

    func tryMapError(target: ExpressAPITarget, response: Response) -> ExpressAPIError? {
        do {
            let error = try JSONDecoder().decode(ExpressDTO.APIError.Response.self, from: response.data)
            return error.error
        } catch {
            return nil
        }
    }
}
