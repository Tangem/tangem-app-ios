//
//  OneInchExchangeProvider.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 08.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OneInchExchangeProvider {
    /// OneInch use this contractAddress for coins
    private let oneInchCoinContractAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    private let defaultSlippage = 1
    private let oneInchAPIProvider: OneInchAPIServicing

    private var bag = Set<AnyCancellable>()

    init(exchangeService: OneInchAPIServicing) {
        oneInchAPIProvider = exchangeService
    }
}

extension OneInchExchangeProvider: ExchangeProvider {
    // MARK: - Fetch data

    func fetchAmountAllowance(for currency: Currency, walletAddress: String) async throws -> Decimal {
        guard let contractAddress = currency.contractAddress else {
            throw Errors.noData
        }

        let parameters = ApproveAllowanceParameters(
            tokenAddress: contractAddress,
            walletAddress: walletAddress
        )

        let allowanceResult = await oneInchAPIProvider.allowance(
            blockchain: currency.blockchain,
            allowanceParameters: parameters
        )

        switch allowanceResult {
        case .success(let allowanceInfo):
            return Decimal(string: allowanceInfo.allowance) ?? 0
        case .failure(let error):
            throw error
        }
    }

    func fetchExchangeData(items: ExchangeItems, walletAddress: String, amount: String, referrer: ExchangeReferrerAccount?) async throws -> ExchangeDataModel {
        let destination = items.destination
        let parameters = ExchangeParameters(
            fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
            toTokenAddress: destination?.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            fromAddress: walletAddress,
            slippage: defaultSlippage,
            referrerAddress: referrer?.address,
            fee: referrer?.fee.description
        )

        let result = await oneInchAPIProvider.swap(blockchain: items.source.blockchain, parameters: parameters)

        switch result {
        case .success(let exchangeData):
            return try ExchangeDataModel(exchangeData: exchangeData)
        case .failure(let error):
            throw error
        }
    }

    func fetchQuote(items: ExchangeItems, amount: String, referrer: ExchangeReferrerAccount?) async throws -> QuoteDataModel {
        let parameters = QuoteParameters(
            fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
            toTokenAddress: items.destination?.contractAddress ?? oneInchCoinContractAddress,
            amount: amount,
            fee: referrer?.fee.description
        )

        let result = await oneInchAPIProvider.quote(blockchain: items.source.blockchain, parameters: parameters)

        switch result {
        case .success(let quoteData):
            return try QuoteDataModel(quoteData: quoteData)
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Approve API

    func fetchApproveExchangeData(for currency: Currency) async throws -> ExchangeApprovedDataModel {
        guard let contractAddress = currency.contractAddress else {
            throw Errors.noData
        }

        let parameters = ApproveTransactionParameters(tokenAddress: contractAddress, amount: .infinite)
        let txResponse = await oneInchAPIProvider.approveTransaction(
            blockchain: currency.blockchain,
            approveTransactionParameters: parameters
        )

        switch txResponse {
        case .success(let approveTxData):
            return try ExchangeApprovedDataModel(approveTxData: approveTxData)
        case .failure(let error):
            throw error
        }
    }

    func fetchSpenderAddress(for currency: Currency) async throws -> String {
        let spender = await oneInchAPIProvider.spender(blockchain: currency.blockchain)

        switch spender {
        case .success(let spender):
            return spender.address
        case .failure(let error):
            throw error
        }
    }
}
