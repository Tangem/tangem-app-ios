//
//  TangemExchangeFactory.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 15.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Public factory for work with exchange
public struct TangemExchangeFactory {
    public init() {}

    public func createExchangeManager(
        walletDataProvider: WalletDataProvider,
        referrer: ExchangeReferrerAccount? = nil,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil,
        logger: ExchangeLogger? = nil
    ) -> ExchangeManager {
        let exchangeItems = ExchangeItems(source: source, destination: destination)
        let exchangeService = OneInchAPIService(logger: logger ?? DefaultExchangeLogger())
        let provider = OneInchExchangeProvider(exchangeService: exchangeService)

        return DefaultExchangeManager(
            exchangeProvider: provider,
            walletDataProvider: walletDataProvider,
            logger: logger ?? DefaultExchangeLogger(),
            referrer: referrer,
            exchangeItems: exchangeItems,
            amount: amount
        )
    }
}
