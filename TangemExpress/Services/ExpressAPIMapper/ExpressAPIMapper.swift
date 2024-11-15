//
//  ExpressAPIMapper.swift
//  TangemExpress
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

    // MARK: - Swap

    func mapToExpressCurrency(currency: ExpressDTO.Currency) -> ExpressCurrency {
        ExpressCurrency(contractAddress: currency.contractAddress, network: currency.network)
    }

    func mapToExpressPair(response: ExpressDTO.Swap.Pairs.Response) -> ExpressPair {
        ExpressPair(
            source: mapToExpressCurrency(currency: response.from),
            destination: mapToExpressCurrency(currency: response.to),
            providers: response.providers.map { .init($0.providerId) }
        )
    }

    func mapToExpressAsset(response: ExpressDTO.Swap.Assets.Response) -> ExpressAsset {
        ExpressAsset(
            currency: ExpressCurrency(contractAddress: response.contractAddress, network: response.network),
            isExchangeable: response.exchangeAvailable,
            isOnrampable: response.onrampAvailable ?? false
        )
    }

    func mapToExpressProvider(provider: ExpressDTO.Swap.Providers.Response) -> ExpressProvider {
        ExpressProvider(
            id: .init(provider.id),
            name: provider.name,
            type: provider.type ?? .unknown,
            imageURL: provider.imageSmall.flatMap(URL.init(string:)),
            termsOfUse: provider.termsOfUse.flatMap(URL.init(string:)),
            privacyPolicy: provider.privacyPolicy.flatMap(URL.init(string:)),
            recommended: provider.recommended,
            slippage: provider.slippage
        )
    }

    func mapToExpressQuote(response: ExpressDTO.Swap.ExchangeQuote.Response) throws -> ExpressQuote {
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

    func mapToExpressTransactionData(
        item: ExpressSwappableItem,
        request: ExpressDTO.Swap.ExchangeData.Request,
        response: ExpressDTO.Swap.ExchangeData.Response
    ) throws -> ExpressTransactionData {
        let txDetails: DecodedTransactionDetails = try exchangeDataDecoder.decode(
            txDetailsJson: response.txDetailsJson,
            signature: response.signature
        )

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

        switch item.providerInfo.type {
        case .cex:
            // For CEX we have txValue amount as value which have to be sent
            txValue /= pow(10, item.source.decimalCount)
        case .dex, .dexBridge:
            // For DEX we have txValue amount as coin. Because it's EVM
            txValue /= pow(10, item.source.feeCurrencyDecimalCount)
        case .onramp, .unknown:
            throw ExpressAPIMapperError.wrongProviderType
        }

        let otherNativeFee = txDetails.otherNativeFee
            .flatMap(Decimal.init)
            .map { $0 / pow(10, item.source.feeCurrencyDecimalCount) }

        return ExpressTransactionData(
            requestId: txDetails.requestId,
            fromAmount: fromAmount,
            toAmount: toAmount,
            expressTransactionId: response.txId,
            transactionType: txDetails.txType,
            sourceAddress: txDetails.txFrom,
            destinationAddress: txDetails.txTo,
            extraDestinationId: txDetails.txExtraId,
            txValue: txValue,
            txData: txDetails.txData,
            otherNativeFee: otherNativeFee,
            estimatedGasLimit: txDetails.gas.flatMap(Int.init),
            externalTxId: txDetails.externalTxId,
            externalTxUrl: txDetails.externalTxUrl
        )
    }

    func mapToExpressTransaction(response: ExpressDTO.Swap.ExchangeStatus.Response) -> ExpressTransaction {
        ExpressTransaction(
            providerId: .init(response.providerId),
            externalStatus: response.status,
            refundedCurrency: mapToRefundedExpressCurrency(response: response)
        )
    }

    private func mapToRefundedExpressCurrency(response: ExpressDTO.Swap.ExchangeStatus.Response) -> ExpressCurrency? {
        guard let refundContractAddress = response.refundContractAddress,
              let refundNetwork = response.refundNetwork else {
            return nil
        }

        return ExpressCurrency(contractAddress: refundContractAddress, network: refundNetwork)
    }

    // MARK: - Onramp

    func mapToOnrampFiatCurrency(response: ExpressDTO.Onramp.FiatCurrency) -> OnrampFiatCurrency {
        let identity = OnrampIdentity(name: response.name, code: response.code, image: URL(string: response.image))
        return OnrampFiatCurrency(identity: identity, precision: response.precision)
    }

    func mapToOnrampCountry(response: ExpressDTO.Onramp.Country) -> OnrampCountry {
        let identity = OnrampIdentity(name: response.name, code: response.code, image: URL(string: response.image))
        let currency = mapToOnrampFiatCurrency(response: response.defaultCurrency)
        return OnrampCountry(identity: identity, currency: currency, onrampAvailable: response.onrampAvailable)
    }

    func mapToOnrampPaymentMethod(response: ExpressDTO.Onramp.PaymentMethod) -> OnrampPaymentMethod? {
        let method = OnrampPaymentMethod(id: response.id, name: response.name, image: response.image)

        if method.type == .googlePay {
            return nil
        }

        return method
    }

    func mapToOnrampPair(response: ExpressDTO.Onramp.Pairs.Response) -> OnrampPair {
        OnrampPair(
            fiatCurrencyCode: response.fromCurrencyCode,
            currency: mapToExpressCurrency(currency: response.to),
            providers: response.providers.map { provider in
                OnrampPair.Provider(id: provider.providerId, paymentMethods: provider.paymentMethods)
            }
        )
    }

    func mapToOnrampQuote(response: ExpressDTO.Onramp.Quote.Response) throws -> OnrampQuote {
        guard let toAmount = Decimal(string: response.toAmount) else {
            throw ExpressAPIMapperError.mapToDecimalError(response.toAmount)
        }

        return OnrampQuote(expectedAmount: toAmount)
    }

    func mapToOnrampRedirectData(
        item: OnrampRedirectDataRequestItem,
        request: ExpressDTO.Onramp.Data.Request,
        response: ExpressDTO.Onramp.Data.Response
    ) throws -> OnrampRedirectData {
        let redirectData: OnrampRedirectData = try exchangeDataDecoder.decode(
            txDetailsJson: response.dataJson,
            signature: response.signature
        )

        guard request.requestId == redirectData.requestId else {
            throw ExpressAPIMapperError.requestIdNotEqual
        }

        return redirectData
    }
}

enum ExpressAPIMapperError: LocalizedError {
    case mapToDecimalError(_ string: String)
    case requestIdNotEqual
    case payoutAddressNotEqual
    case wrongProviderType

    var errorDescription: String? {
        switch self {
        case .mapToDecimalError(let value): "Wrong decimal value \(value)"
        case .requestIdNotEqual: "Request id is not matched with value in the request"
        case .payoutAddressNotEqual: "Payout address is not matched with value in the request"
        case .wrongProviderType: "Provider type is not support"
        }
    }
}
