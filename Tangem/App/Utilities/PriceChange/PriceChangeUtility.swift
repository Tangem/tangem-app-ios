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

    func convertToPriceChangeState(change: Decimal?) -> TokenPriceChangeView.State {
        guard let result = formatPriceChange(change) else {
            return .noData
        }

        return .loaded(signType: result.signType, text: result.formattedText)
    }

    func convertToPriceChangeState(changePercent: Decimal?) -> TokenPriceChangeView.State {
        guard
            let changePercent,
            let result = formatPriceChange(changePercent * Constants.percentDivider)
        else {
            return .noData
        }

        return .loaded(signType: result.signType, text: result.formattedText)
    }

    func calculatePriceChangeStateBetween(currentPrice: Decimal, previousPrice: Decimal) -> TokenPriceChangeView.State {
        let priceChangePercentage = (currentPrice - previousPrice) / previousPrice * 100.0

        return convertToPriceChangeState(changePercent: priceChangePercentage)
    }

    private func formatPriceChange(_ change: Decimal?) -> PriceChangeFormatter.Result? {
        guard let change else {
            return nil
        }

        return priceChangeFormatter.format(change, option: .priceChange)
    }
}

private extension PriceChangeUtility {
    enum Constants {
        static let percentDivider: Decimal = 0.01
    }
}
