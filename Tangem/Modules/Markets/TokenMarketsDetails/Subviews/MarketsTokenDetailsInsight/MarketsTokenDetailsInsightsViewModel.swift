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

    private let currencySymbolProvider: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current

        let currencyCode = AppSettings.shared.selectedCurrencyCode
        numberFormatter.currencyCode = currencyCode

        if currencyCode == AppConstants.rubCurrencyCode {
            numberFormatter.currencySymbol = AppConstants.rubSign
        }

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

        func useDefaultFormat(for value: Decimal?) -> String {
            guard let value else {
                return missingValue
            }

            return amountNotationFormatter.formatWithNotation(value, roundingType: roundingType).fullDescription
        }

        intervalInsights = availableIntervals.reduce(into: [:]) { partialResult, interval in
            let buyers = useDefaultFormat(for: insights.experiencedBuyers[interval])
            let holders = useDefaultFormat(for: insights.holders[interval])
            let liquidity = useDefaultFormat(for: insights.liquidity[interval])

            var buyPressure = missingValue
            if let buyPressureValue = insights.buyPressure[interval] {
                let result = amountNotationFormatter.formatWithNotation(buyPressureValue, roundingType: roundingType)
                buyPressure = "\(result.signPrefix) \(currencySymbolProvider.currencySymbol ?? "") \(abs(result.decimal)) \(result.suffix)"
            }

            partialResult[interval] = [
                .init(type: .buyers, recordData: buyers),
                .init(type: .buyPressure, recordData: buyPressure),
                .init(type: .holdersChange, recordData: holders),
                .init(type: .liquidity, recordData: liquidity),
            ]
        }
    }
}
