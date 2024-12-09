//
//  CommonExpressAPIProvider.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonExpressAPIProvider {
    let expressAPIService: ExpressAPIService
    let expressAPIMapper: ExpressAPIMapper

    init(expressAPIService: ExpressAPIService, expressAPIMapper: ExpressAPIMapper) {
        self.expressAPIService = expressAPIService
        self.expressAPIMapper = expressAPIMapper
    }
}

// MARK: - ExpressAPIProvider

extension CommonExpressAPIProvider: ExpressAPIProvider {
    // MARK: - Swap

    /// Requests from Express API `exchangeAvailable` state for currencies included in filter
    /// - Returns: All `ExpressCurrency` that available to exchange specified by filter
    func assets(currencies: Set<ExpressCurrency>) async throws -> [ExpressAsset] {
        let tokens = currencies.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let request = ExpressDTO.Swap.Assets.Request(tokensList: tokens)
        let response = try await expressAPIService.assets(request: request)
        let assets: [ExpressAsset] = response.map(expressAPIMapper.mapToExpressAsset(response:))
        return assets
    }

    func pairs(from: [ExpressCurrency], to: [ExpressCurrency]) async throws -> [ExpressPair] {
        let from = from.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let to = to.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let request = ExpressDTO.Swap.Pairs.Request(from: from, to: to)
        let response = try await expressAPIService.pairs(request: request)
        let pairs = response.map(expressAPIMapper.mapToExpressPair(response:))
        return pairs
    }

    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] {
        let response = try await expressAPIService.providers()
        let providers = response
            .map(expressAPIMapper.mapToExpressProvider(provider:))
            .filter { branch.supportedProviderTypes.contains($0.type) }

        return providers
    }

    func exchangeQuote(item: ExpressSwappableItem) async throws -> ExpressQuote {
        let request = ExpressDTO.Swap.ExchangeQuote.Request(
            fromContractAddress: item.source.expressCurrency.contractAddress,
            fromNetwork: item.source.expressCurrency.network,
            toContractAddress: item.destination.expressCurrency.contractAddress,
            toNetwork: item.destination.expressCurrency.network,
            toDecimals: item.destination.decimalCount,
            fromAmount: item.sourceAmountWEI(),
            fromDecimals: item.source.decimalCount,
            providerId: item.providerInfo.id,
            rateType: .float
        )

        let response = try await expressAPIService.exchangeQuote(request: request)
        var quote = try expressAPIMapper.mapToExpressQuote(response: response)
        // We have to check the "fromAmount" because sometimes we can receive it more then was sent
        if quote.fromAmount > item.amount {
            quote.fromAmount = item.amount
        }

        return quote
    }

    func exchangeData(item: ExpressSwappableItem) async throws -> ExpressTransactionData {
        let requestId: String = UUID().uuidString
        let request = ExpressDTO.Swap.ExchangeData.Request(
            requestId: requestId,
            fromAddress: item.source.defaultAddress,
            fromContractAddress: item.source.expressCurrency.contractAddress,
            fromNetwork: item.source.expressCurrency.network,
            toContractAddress: item.destination.expressCurrency.contractAddress,
            toNetwork: item.destination.expressCurrency.network,
            toDecimals: item.destination.decimalCount,
            fromAmount: item.sourceAmountWEI(),
            fromDecimals: item.source.decimalCount,
            providerId: item.providerInfo.id,
            rateType: .float,
            toAddress: item.destination.defaultAddress,
            refundAddress: item.source.defaultAddress,
            refundExtraId: nil // There is no memo on the client side
        )

        let response = try await expressAPIService.exchangeData(request: request)
        let data = try expressAPIMapper.mapToExpressTransactionData(item: item, request: request, response: response)
        return data
    }

    func exchangeStatus(transactionId: String) async throws -> ExpressTransaction {
        let request = ExpressDTO.Swap.ExchangeStatus.Request(txId: transactionId)
        let response = try await expressAPIService.exchangeStatus(request: request)
        let transaction = expressAPIMapper.mapToExpressTransaction(response: response)
        return transaction
    }

    func exchangeSent(result: ExpressTransactionSentResult) async throws {
        let request = ExpressDTO.Swap.ExchangeSent.Request(
            txHash: result.hash,
            txId: result.data.expressTransactionId,
            fromNetwork: result.source.expressCurrency.network,
            fromAddress: result.source.defaultAddress,
            payinAddress: result.data.destinationAddress,
            payinExtraId: result.data.extraDestinationId
        )

        _ = try await expressAPIService.exchangeSent(request: request)
    }

    // MARK: - Onramp

    func onrampCurrencies() async throws -> [OnrampFiatCurrency] {
        let response = try await expressAPIService.onrampCurrencies()
        let currencies = response.map(expressAPIMapper.mapToOnrampFiatCurrency(response:))
        return currencies
    }

    func onrampCountries() async throws -> [OnrampCountry] {
        let response = try await expressAPIService.onrampCountries()
        let countries = response.map(expressAPIMapper.mapToOnrampCountry(response:))
        return countries
    }

    func onrampCountryByIP() async throws -> OnrampCountry {
        let response = try await expressAPIService.onrampCountryByIP()
        let country = expressAPIMapper.mapToOnrampCountry(response: response)
        return country
    }

    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod] {
        let response = try await expressAPIService.onrampPaymentMethods()
        let methods = response.compactMap(expressAPIMapper.mapToOnrampPaymentMethod(response:))
        return methods
    }

    func onrampPairs(from fiat: OnrampFiatCurrency, to: [ExpressCurrency], country: OnrampCountry) async throws -> [OnrampPair] {
        let to = to.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let request = ExpressDTO.Onramp.Pairs.Request(fromCurrencyCode: fiat.identity.code, countryCode: country.identity.code, to: to)
        let response = try await expressAPIService.onrampPairs(request: request)
        let pairs = response.map(expressAPIMapper.mapToOnrampPair(response:))
        return pairs
    }

    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote {
        let request = ExpressDTO.Onramp.Quote.Request(
            fromCurrencyCode: item.pairItem.fiatCurrency.identity.code,
            toContractAddress: item.pairItem.destination.expressCurrency.contractAddress,
            toNetwork: item.pairItem.destination.expressCurrency.network,
            paymentMethod: item.paymentMethod.id,
            countryCode: item.pairItem.country.identity.code,
            fromPrecision: item.pairItem.fiatCurrency.precision,
            fromAmount: item.sourceAmountWEI(),
            toDecimals: item.pairItem.destination.decimalCount,
            providerId: item.providerInfo.id
        )

        let response = try await expressAPIService.onrampQuote(request: request)
        let quote = try expressAPIMapper.mapToOnrampQuote(response: response)
        return quote
    }

    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData {
        let requestId: String = UUID().uuidString
        let request = ExpressDTO.Onramp.Data.Request(
            fromCurrencyCode: item.quotesItem.pairItem.fiatCurrency.identity.code,
            toContractAddress: item.quotesItem.pairItem.destination.expressCurrency.contractAddress,
            toNetwork: item.quotesItem.pairItem.destination.expressCurrency.network,
            paymentMethod: item.quotesItem.paymentMethod.id,
            countryCode: item.quotesItem.pairItem.country.identity.code,
            fromAmount: item.quotesItem.sourceAmountWEI(),
            fromPrecision: item.quotesItem.pairItem.fiatCurrency.precision,
            toDecimals: item.quotesItem.pairItem.destination.decimalCount,
            providerId: item.quotesItem.providerInfo.id,
            toAddress: item.quotesItem.pairItem.destination.defaultAddress,
            toExtraId: nil, // There is no memo on the client side
            redirectUrl: item.redirectSettings.successURL,
            language: item.redirectSettings.language,
            theme: item.redirectSettings.theme.rawValue,
            requestId: requestId
        )

        let response = try await expressAPIService.onrampData(request: request)
        let data = try expressAPIMapper.mapToOnrampRedirectData(item: item, request: request, response: response)
        return data
    }

    func onrampStatus(transactionId: String) async throws -> OnrampTransaction {
        let request = ExpressDTO.Onramp.Status.Request(txId: transactionId)
        let response = try await expressAPIService.onrampStatus(request: request)
        return try expressAPIMapper.mapToOnrampTransaction(response: response)
    }
}
