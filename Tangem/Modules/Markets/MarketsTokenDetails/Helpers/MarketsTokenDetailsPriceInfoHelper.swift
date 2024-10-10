//
//  MarketsTokenDetailsPriceInfoHelper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenDetailsPriceInfoHelper {
    typealias PriceInfo = (price: String, priceChangeState: TokenPriceChangeView.State)

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = MarketsTokenPriceFormatter()

    /// This overload should be used when the interval of interest is defined by the value selected on the chart.
    func makePriceInfo(
        currentPrice: Decimal,
        selectedPrice: Decimal
    ) -> PriceInfo {
        let priceChangeState = priceChangeUtility.calculatePriceChangeStateBetween(
            currentPrice: currentPrice,
            previousPrice: selectedPrice
        )
        let price = priceFormatter.formatPrice(selectedPrice)

        return (price, priceChangeState)
    }

    /// This overload should be used when the interval of interest is selected on the interval selector.
    func makePriceInfo(
        currentPrice: Decimal,
        priceChangeInfo: [String: Decimal],
        selectedPriceChangeIntervalType: MarketsPriceIntervalType
    ) -> PriceInfo {
        let changePercent = priceChangeInfo[selectedPriceChangeIntervalType.rawValue]
        let priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: changePercent)
        let price = priceFormatter.formatPrice(currentPrice)

        return (price, priceChangeState)
    }
}
