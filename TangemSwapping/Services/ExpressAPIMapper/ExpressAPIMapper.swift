//
//  ExpressAPIMapper.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressAPIMapper {
    let exchangeDataDecoder: ExpressExchangeDataDecoder

    // MARK: - Map to DTO

    func mapToDTOCurrency(currency: ExpressCurrency) -> ExpressDTO.Currency {
        ExpressDTO.Currency(contractAddress: currency.contractAddress, network: currency.network)
    }

    // MARK: - Map to domain

    func mapToExpressCurrency(currency: ExpressDTO.Currency) -> ExpressCurrency {
        ExpressCurrency(contractAddress: currency.contractAddress, network: currency.network)
    }

    func mapToExpressPair(response: ExpressDTO.Pairs.Response) -> ExpressPair {
        ExpressPair(
            source: mapToExpressCurrency(currency: response.from),
            destination: mapToExpressCurrency(currency: response.to),
            providers: response.providers.map { .init($0.providerId) }
        )
    }

    func mapToExpressAsset(response: ExpressDTO.Assets.Response) -> ExpressAsset {
        ExpressAsset(
            currency: ExpressCurrency(contractAddress: response.contractAddress, network: response.network),
            isExchangeable: response.exchangeAvailable
        )
    }

    func mapToExpressProvider(provider: ExpressDTO.Providers.Response) -> ExpressProvider {
        ExpressProvider(
            id: .init(provider.id),
            name: provider.name,
            type: provider.type,
            imageURL: provider.imageSmall.flatMap(URL.init(string:)),
            termsOfUse: provider.termsOfUse.flatMap(URL.init(string:)),
            privacyPolicy: provider.privacyPolicy.flatMap(URL.init(string:))
        )
    }

    func mapToExpressQuote(response: ExpressDTO.ExchangeQuote.Response) throws -> ExpressQuote {
        guard var fromAmount = Decimal(string: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        guard var toAmount = Decimal(string: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        fromAmount /= pow(10, response.fromDecimals)
        toAmount /= pow(10, response.toDecimals)

        return ExpressQuote(
            fromAmount: fromAmount,
            expectAmount: toAmount,
            allowanceContract: response.allowanceContract
        )
    }

    func mapToExpressTransactionData(request: ExpressDTO.ExchangeData.Request, response: ExpressDTO.ExchangeData.Response) throws -> ExpressTransactionData {
        let txDetails = try exchangeDataDecoder.decode(txDetailsJson: response.txDetailsJson, signature: response.signature)

        guard request.requestId == txDetails.requestId else {
            throw ExpressAPIMapperError.requestIdNotEqual
        }

        guard request.toAddress.caseInsensitiveCompare(txDetails.payoutAddress) == .orderedSame else {
            throw ExpressAPIMapperError.payoutAddressNotEqual
        }

        guard var fromAmount = Decimal(string: response.fromAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.fromAmount)
        }

        guard var toAmount = Decimal(string: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        guard var txValue = Decimal(string: txDetails.txValue) else {
            throw ExpressAPIMapperError.mapToDecimalError(txDetails.txValue)
        }

        fromAmount /= pow(10, response.fromDecimals)
        toAmount /= pow(10, response.toDecimals)
        txValue /= pow(10, response.fromDecimals)

        return ExpressTransactionData(
            requestId: txDetails.requestId,
            fromAmount: fromAmount,
            toAmount: toAmount,
            expressTransactionId: response.txId,
            transactionType: txDetails.txType,
            sourceAddress: txDetails.txFrom,
            destinationAddress: txDetails.txTo,
            extraDestinationId: txDetails.txExtraId,
            value: txValue,
            txData: txDetails.txData,
            externalTxId: txDetails.externalTxId,
            externalTxUrl: txDetails.externalTxUrl
        )
    }

    func mapToExpressTransaction(response: ExpressDTO.ExchangeStatus.Response) -> ExpressTransaction {
        ExpressTransaction(
            providerId: .init(response.providerId),
            externalStatus: response.externalTxStatus,
            externalTxId: response.externalTxId,
            externalTxUrl: response.externalTxUrl
        )
    }
}

enum ExpressAPIMapperError: Error {
    case mapToDecimalError(_ string: String)
    case requestIdNotEqual
    case payoutAddressNotEqual
}
