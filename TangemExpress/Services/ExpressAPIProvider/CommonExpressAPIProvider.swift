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
    /// Requests from Express API `exchangeAvailable` state for currencies included in filter
    /// - Returns: All `ExpressCurrency` that available to exchange specified by filter
    func assets(with filter: [ExpressCurrency]) async throws -> [ExpressAsset] {
        let tokens = filter.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let request = ExpressDTO.Assets.Request(tokensList: tokens)
        let response = try await expressAPIService.assets(request: request)
        let assets: [ExpressAsset] = response.map(expressAPIMapper.mapToExpressAsset(response:))
        return assets
    }

    func pairs(from: [ExpressCurrency], to: [ExpressCurrency]) async throws -> [ExpressPair] {
        let from = from.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let to = to.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let request = ExpressDTO.Pairs.Request(from: from, to: to)
        let response = try await expressAPIService.pairs(request: request)
        let pairs = response.map(expressAPIMapper.mapToExpressPair(response:))
        return pairs
    }

    func providers() async throws -> [ExpressProvider] {
        let response = try await expressAPIService.providers()
        let providers = response.map(expressAPIMapper.mapToExpressProvider(provider:))
        return providers
    }

    func exchangeQuote(item: ExpressSwappableItem) async throws -> ExpressQuote {
        let request = ExpressDTO.ExchangeQuote.Request(
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
        let request = ExpressDTO.ExchangeData.Request(
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
        let request = ExpressDTO.ExchangeStatus.Request(txId: transactionId)
        let response = try await expressAPIService.exchangeStatus(request: request)
        let transaction = expressAPIMapper.mapToExpressTransaction(response: response)
        return transaction
    }

    func exchangeSent(result: ExpressTransactionSentResult) async throws {
        let request = ExpressDTO.ExchangeSent.Request(
            txHash: result.hash,
            txId: result.data.expressTransactionId,
            fromNetwork: result.source.expressCurrency.network,
            fromAddress: result.source.defaultAddress,
            payinAddress: result.data.destinationAddress,
            payinExtraId: result.data.extraDestinationId
        )

        _ = try await expressAPIService.exchangeSent(request: request)
    }
}
