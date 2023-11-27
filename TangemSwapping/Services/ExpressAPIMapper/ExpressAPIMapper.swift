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

    func mapToExpressQuote(response: ExpressDTO.ExchangeQuote.Response) throws -> ExpressQuote {
        guard var fromAmount = Decimal(string: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        guard var toAmount = Decimal(string: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        guard var minAmount = Decimal(string: response.minAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.minAmount)
        }

        fromAmount /= pow(10, response.fromDecimals)
        toAmount /= pow(10, response.toDecimals)
        minAmount /= pow(10, response.fromDecimals)

        return ExpressQuote(
            fromAmount: fromAmount,
            expectAmount: toAmount,
            minAmount: minAmount,
            allowanceContract: response.allowanceContract
        )
    }

    func mapToExpressTransactionData(response: ExpressDTO.ExchangeData.Response) throws -> ExpressTransactionData {
        guard var fromAmount = Decimal(string: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        guard var toAmount = Decimal(string: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        guard var txValue = Decimal(string: response.txValue) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.txValue)
        }

        fromAmount /= pow(10, response.fromDecimals)
        toAmount /= pow(10, response.toDecimals)
        txValue /= pow(10, response.fromDecimals)

        return ExpressTransactionData(
            fromAmount: fromAmount,
            toAmount: toAmount,
            expressTransactionId: response.txId,
            transactionType: response.txType,
            sourceAddress: response.txFrom,
            destinationAddress: response.txTo,
            value: txValue,
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

enum ExpressAPIMapperError: Error {
    case mapToDecimalError(_ string: String)
}
