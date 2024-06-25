//
//  TokenMarketsDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TokenMarketsDetailsViewModel: ObservableObject {
    @Published var price: String
    @Published var priceChangeState: TokenPriceChangeView.State

    var tokenName: String {
        tokenInfo.name
    }

    var priceDate: String {
        return dateFormatter.string(from: displayingDate)
    }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    @Published private var displayingDate: Date = .init()

    private let balanceFormatter = BalanceFormatter()
    private let priceChangeUtility = PriceChangeUtility()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    private let tokenInfo: MarketsTokenModel

    init(tokenInfo: MarketsTokenModel) {
        self.tokenInfo = tokenInfo

        price = balanceFormatter.formatFiatBalance(
            tokenInfo.currentPrice,
            formattingOptions: .init(
                minFractionDigits: 2,
                maxFractionDigits: 8,
                formatEpsilonAsLowestRepresentableValue: false,
                roundingType: .defaultFiat(roundingMode: .bankers)
            )
        )
        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: tokenInfo.priceChangePercentage[MarketsPriceIntervalType.day.rawValue])
    }
}
