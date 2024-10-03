//
//  PriceChangeUtility.swift
//  Tangem
//
//  Created by Andrew Son on 25/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PriceChangeUtility {
    private let priceChangeFormatter = PriceChangeFormatter()

    func convertToPriceChangeState(changeFractional: Decimal?) -> TokenPriceChangeView.State {
        guard let changeFractional else {
            return .noData
        }

        let result = priceChangeFormatter.formatFractionalValue(changeFractional, option: .priceChange)
        return .loaded(signType: result.signType, text: result.formattedText)
    }

    func convertToPriceChangeState(changePercent: Decimal?) -> TokenPriceChangeView.State {
        guard let changePercent else {
            return .noData
        }

        let result = priceChangeFormatter.formatPercentValue(changePercent, option: .priceChange)
        return .loaded(signType: result.signType, text: result.formattedText)
    }

    func calculatePriceChangeStateBetween(currentPrice: Decimal, previousPrice: Decimal) -> TokenPriceChangeView.State {
        let priceChangePercentage = (currentPrice - previousPrice) / previousPrice * 100.0

        return convertToPriceChangeState(changePercent: priceChangePercentage)
    }
}

private extension PriceChangeUtility {
    enum Constants {
        static let percentDivider: Decimal = 0.01
    }
}
