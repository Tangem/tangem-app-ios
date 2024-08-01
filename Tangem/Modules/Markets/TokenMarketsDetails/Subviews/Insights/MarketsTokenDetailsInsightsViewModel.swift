//
//  MarketsTokenDetailsInsightsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 09/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsTokenDetailsBottomSheetRouter: AnyObject {
    func openInfoBottomSheet(title: String, message: String)
}

protocol MarketsTokenDetailsInfoDescriptionProvider {
    var title: String { get }
    var infoDescription: String { get }
}

class MarketsTokenDetailsInsightsViewModel: ObservableObject {
    @Published var selectedInterval: MarketsPriceIntervalType = .day

    let availableIntervals: [MarketsPriceIntervalType] = [.day, .week, .month]

    var records: [MarketsTokenDetailsInsightsView.RecordInfo] {
        intervalInsights[selectedInterval] ?? []
    }

    private let fiatAmountFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.usesGroupingSeparator = true

        let currencyCode = AppSettings.shared.selectedCurrencyCode
        numberFormatter.currencyCode = currencyCode

        switch currencyCode {
        case AppConstants.rubCurrencyCode:
            numberFormatter.currencySymbol = AppConstants.rubSign
        case AppConstants.usdCurrencyCode:
            numberFormatter.currencySymbol = AppConstants.usdSign
        default:
            break
        }

        return numberFormatter
    }()

    private let nonCurrencyFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.usesGroupingSeparator = true
        return numberFormatter
    }()

    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?
    private var intervalInsights: [MarketsPriceIntervalType: [MarketsTokenDetailsInsightsView.RecordInfo]] = [:]

    init(insights: TokenMarketsDetailsInsights, infoRouter: MarketsTokenDetailsBottomSheetRouter?) {
        self.infoRouter = infoRouter

        setupInsights(using: insights)
    }

    func showInfoBottomSheet(for infoProvider: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: infoProvider.title, message: infoProvider.infoDescription)
    }

    private func setupInsights(using insights: TokenMarketsDetailsInsights) {
        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let roundingType = AmountRoundingType.default(roundingMode: .plain, scale: 1)
        let missingValue = AppConstants.dashSign

        func formatAmount(_ value: Decimal?, using formatter: NumberFormatter) -> String {
            guard let value else {
                return missingValue
            }

            let amountWithNotation = amountNotationFormatter.formatWithNotation(value, roundingType: roundingType)
            let formattedAmount = formatter.string(from: abs(amountWithNotation.decimal) as NSDecimalNumber) ?? "0"
            return "\(amountWithNotation.signPrefix)\(formattedAmount)\(amountWithNotation.suffix)"
        }

        intervalInsights = availableIntervals.reduce(into: [:]) { partialResult, interval in
            let buyers = formatAmount(insights.experiencedBuyers[interval], using: nonCurrencyFormatter)
            let holders = formatAmount(insights.holders[interval], using: nonCurrencyFormatter)
            let liquidity = formatAmount(insights.liquidity[interval], using: nonCurrencyFormatter)

            let buyPressure = formatAmount(insights.buyPressure[interval], using: fiatAmountFormatter)

            partialResult[interval] = [
                .init(type: .buyers, recordData: buyers),
                .init(type: .buyPressure, recordData: buyPressure),
                .init(type: .holdersChange, recordData: holders),
                .init(type: .liquidity, recordData: liquidity),
            ]
        }
    }
}
