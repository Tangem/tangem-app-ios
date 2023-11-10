//
//  ExpressAPIMapper.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressAPIMapper {
    // MARK: - Map to DTO

    func mapToDTOCurrency(currency: ExpressCurrency) -> ExpressDTO.Currency {
        ExpressDTO.Currency(contractAddress: currency.contractAddress, network: currency.network)
    }

    // MARK: - Map to domain

    func mapToExpressCurrency(currency: ExpressDTO.Currency) -> ExpressCurrency {
        ExpressCurrency(contractAddress: currency.contractAddress, network: currency.network)
    }

    func mapToExpressAsset(currency: ExpressDTO.Assets.Response) -> ExpressAsset {
        ExpressAsset(
            currency: .init(contractAddress: currency.contractAddress, network: currency.network),
            token: currency.token,
            name: currency.name,
            symbol: currency.symbol,
            decimals: currency.decimals,
            exchangeAvailable: currency.exchangeAvailable,
            onrampAvailable: currency.onrampAvailable,
            offrampAvailable: currency.offrampAvailable
        )
    }

    func mapToExpressPair(response: ExpressDTO.Pairs.Response) -> ExpressPair {
        ExpressPair(
            source: mapToExpressCurrency(currency: response.from),
            destination: mapToExpressCurrency(currency: response.to),
            providers: response.providers.map { $0.providerId }
        )
    }

    func mapToExpressProvider(provider: ExpressDTO.Providers.Response) -> ExpressProvider {
        ExpressProvider(
            id: provider.id,
            name: provider.name,
            url: URL(string: provider.imageSmall),
            type: provider.type
        )
    }

    func mapToExpressQuote(response: ExpressDTO.ExchangeQuote.Response) -> ExpressQuote {
        ExpressQuote(
            expectAmount: response.toAmount,
            minAmount: response.minAmount,
            allowanceContract: response.allowanceContract
        )
    }

    func mapToExpressTransactionData(response: ExpressDTO.ExchangeData.Response) -> ExpressTransactionData {
        ExpressTransactionData(
            expressTransactionId: response.txId,
            transactionType: response.txType,
            sourceAddress: response.txFrom,
            destinationAddress: response.txTo,
            value: response.txValue,
            txData: response.txData,
            externalTxId: response.externalTxId,
            externalTxUrl: response.externalTxUrl
        )
    }

    func mapToExpressTransaction(response: ExpressDTO.ExchangeResult.Response) -> ExpressTransaction {
        ExpressTransaction(
            status: response.status,
            externalStatus: response.externalStatus,
            externalTxUrl: response.externalTxUrl,
            errorCode: response.errorCode
        )
    }
}
