//
//  ExchangeProvider.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 08.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeProvider {
    func fetchAmountAllowance(for currency: Currency, walletAddress: String) async throws -> Decimal
    func fetchQuote(items: ExchangeItems, amount: String, referrer: ExchangeReferrerAccount?) async throws -> QuoteDataModel
    func fetchExchangeData(
        items: ExchangeItems,
        walletAddress: String,
        amount: String,
        referrer: ExchangeReferrerAccount?
    ) async throws -> ExchangeDataModel

    func fetchApproveExchangeData(for currency: Currency) async throws -> ExchangeApprovedDataModel
    func fetchSpenderAddress(for currency: Currency) async throws -> String
}
