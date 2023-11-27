//
//  CommonExpressAPIProvider.swift
//  TangemSwapping
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
    func assets(with filter: [ExpressCurrency]) async throws -> [ExpressAsset] {
        let tokens = filter.map(expressAPIMapper.mapToDTOCurrency(currency:))
        let request = ExpressDTO.Assets.Request(tokensList: tokens)
        let response = try await expressAPIService.assets(request: request)
        let assets = response.map(expressAPIMapper.mapToExpressAsset(currency:))
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
            fromContractAddress: item.source.contractAddress,
            fromNetwork: item.source.network,
            toContractAddress: item.destination.contractAddress,
            toNetwork: item.destination.network,
            fromAmount: item.sourceAmountWEI(),
            fromDecimals: item.source.decimalCount,
            providerId: item.providerId,
            rateType: .float
        )

        let response = try await expressAPIService.exchangeQuote(request: request)
        let quote = try expressAPIMapper.mapToExpressQuote(response: response)
        return quote
    }

    func exchangeData(item: ExpressSwappableItem) async throws -> ExpressTransactionData {
        let request = ExpressDTO.ExchangeData.Request(
            fromContractAddress: item.source.contractAddress,
            fromNetwork: item.source.network,
            toContractAddress: item.destination.contractAddress,
            toNetwork: item.destination.network,
            fromAmount: item.sourceAmountWEI(),
            fromDecimals: item.source.decimalCount,
            providerId: item.providerId,
            rateType: .float,
            toAddress: item.destination.defaultAddress
        )

        let response = try await expressAPIService.exchangeData(request: request)
        let data = try expressAPIMapper.mapToExpressTransactionData(response: response)
        return data
    }

    func exchangeResult(transactionId: String) async throws -> ExpressTransaction {
        let request = ExpressDTO.ExchangeResult.Request(txId: transactionId)
        let response = try await expressAPIService.exchangeResult(request: request)
        let transaction = expressAPIMapper.mapToExpressTransaction(response: response)
        return transaction
    }
}
