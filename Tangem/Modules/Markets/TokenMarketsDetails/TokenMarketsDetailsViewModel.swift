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
    @Published var shortDescription: String
    @Published var selectedPriceChangeIntervalType = MarketsPriceIntervalType.day

    let priceChangeIntervalOptions = MarketsPriceIntervalType.allCases

    var priceChangeState: TokenPriceChangeView.State {
        guard let pickedDate else {
            let changePercent = loadedPriceChangeInfo[selectedPriceChangeIntervalType.tokenMarketsDetailsId]
            return priceChangeUtility.convertToPriceChangeState(changePercent: changePercent)
        }

        // TODO: calculate from interval between picked date and now
        print("Price change state for picked date: \(pickedDate)")
        return .noData
    }

    var tokenName: String {
        tokenInfo.name
    }

    var priceDate: String {
        guard let pickedDate else {
            return Localization.commonToday
        }

        return "\(dateFormatter.string(from: pickedDate)) – \(Localization.commonNow)"
    }

    var pickedDate: Date? {
        guard let pickedTimeInterval else {
            return nil
        }

        return Date(timeIntervalSince1970: pickedTimeInterval)
    }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    @Published private var pickedTimeInterval: TimeInterval?
    @Published private var loadedHistoryInfo: [TimeInterval: Decimal] = [:]
    @Published private var loadedPriceChangeInfo: [String: Decimal] = [:]

    private let balanceFormatter = BalanceFormatter()
    private let priceChangeUtility = PriceChangeUtility()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:MM"
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

        loadedHistoryInfo = [Date().timeIntervalSince1970: tokenInfo.priceChangePercentage[MarketsPriceIntervalType.day.marketsListId] ?? 0]
        loadedPriceChangeInfo = tokenInfo.priceChangePercentage

        // TODO: Will be replaced in IOS-7083
        shortDescription = "XRP (XRP) is a cryptocurrency launched in January 2009, where the first genesis block was mined on 9th January 2009."
    }

    // MARK: - Actions

    func onAddToPortfolioTapAction() {
        // TODO: - Need to implement bottom sheet token portfolio
    }
}

extension TokenMarketsDetailsViewModel {
    func openFullDescription() {
        print("Open full description tapped")
    }
}
