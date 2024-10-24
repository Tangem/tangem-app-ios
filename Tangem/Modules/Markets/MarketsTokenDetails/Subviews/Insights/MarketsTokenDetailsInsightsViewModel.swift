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
    var titleShort: String { get }
    var titleFull: String { get }
    var infoDescription: String { get }
}

class MarketsTokenDetailsInsightsViewModel: ObservableObject {
    @Published var selectedInterval: MarketsPriceIntervalType = .day

    let availableIntervals: [MarketsPriceIntervalType] = [.day, .week, .month]

    var records: [MarketsTokenDetailsInsightsView.RecordInfo] {
        intervalInsights[selectedInterval] ?? []
    }

    var shouldShowHeaderInfoButton: Bool {
        insights.networksInfo != nil
    }

    private var fiatAmountFormatter: NumberFormatter = BalanceFormatter().makeDefaultFiatFormatter(
        forCurrencyCode: AppSettings.shared.selectedCurrencyCode,
        formattingOptions: .defaultFiatFormattingOptions
    )

    private let nonCurrencyFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.currencySymbol = ""
        return numberFormatter
    }()

    private let tokenSymbol: String
    private let insights: MarketsTokenDetailsInsights
    private let notationFormatter: DefaultAmountNotationFormatter
    private let insightsPublisher: any Publisher<MarketsTokenDetailsInsights?, Never>

    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?
    private var intervalInsights: [MarketsPriceIntervalType: [MarketsTokenDetailsInsightsView.RecordInfo]] = [:]
    private var bag = Set<AnyCancellable>()

    init(
        tokenSymbol: String,
        insights: MarketsTokenDetailsInsights,
        insightsPublisher: some Publisher<MarketsTokenDetailsInsights?, Never>,
        notationFormatter: DefaultAmountNotationFormatter,
        infoRouter: MarketsTokenDetailsBottomSheetRouter?
    ) {
        self.tokenSymbol = tokenSymbol
        self.insights = insights
        self.notationFormatter = notationFormatter
        self.insightsPublisher = insightsPublisher
        self.infoRouter = infoRouter

        setupInsights()
        bind()
    }

    func showInfoBottomSheet(for infoProvider: MarketsTokenDetailsInfoDescriptionProvider) {
        showInfoBottomSheet(title: infoProvider.titleFull, message: infoProvider.infoDescription)
    }

    func showInsightsSheetInfo() {
        guard let networksInfo = insights.networksInfo else {
            return
        }

        let networksList = networksInfo.map { $0.networkName }.joined(separator: ", ")
        let message = Localization.marketsInsightsInfoDescriptionMessage(networksList)
        showInfoBottomSheet(title: Localization.marketsTokenDetailsInsights, message: message)
    }

    private func setupInsights() {
        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)

        func makeRecord(value: Decimal?, type: MarketsTokenDetailsInsightsView.RecordType, numberFormatter: NumberFormatter) -> MarketsTokenDetailsInsightsView.RecordInfo? {
            guard let value else {
                return nil
            }

            let recordData = notationFormatter.format(
                value,
                notationFormatter: amountNotationFormatter,
                numberFormatter: numberFormatter,
                addingSignPrefix: true
            )

            let trend: MarketsTokenDetailsStatisticsRecordView.Trend? = value > 0 ? .positive : value < 0 ? .negative : nil
            return .init(type: type, recordData: recordData, trend: trend)
        }

        intervalInsights = availableIntervals.reduce(into: [:]) { partialResult, interval in
            let records: [MarketsTokenDetailsInsightsView.RecordInfo?] = [
                makeRecord(value: insights.experiencedBuyers[interval], type: .buyers, numberFormatter: nonCurrencyFormatter),
                makeRecord(value: insights.holders[interval], type: .holdersChange, numberFormatter: nonCurrencyFormatter),
                makeRecord(value: insights.liquidity[interval], type: .liquidity, numberFormatter: fiatAmountFormatter),
                makeRecord(value: insights.buyPressure[interval], type: .buyPressure, numberFormatter: fiatAmountFormatter),
            ]
            partialResult[interval] = records.compactMap { $0 }
        }
    }

    private func bind() {
        $selectedInterval
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { value in
                let weakSelf = value.0
                let interval = value.1

                Analytics.log(
                    event: .marketsChartButtonPeriod,
                    params: [
                        .token: weakSelf.tokenSymbol.uppercased(),
                        .period: interval.analyticsParameterValue,
                        .source: Analytics.MarketsIntervalTypeSourceType.insights.rawValue,
                    ]
                )
            })
            .store(in: &bag)

        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.fiatAmountFormatter = BalanceFormatter().makeDefaultFiatFormatter(
                    forCurrencyCode: newCurrencyCode,
                    formattingOptions: .defaultFiatFormattingOptions
                )
                viewModel.setupInsights()
            }
            .store(in: &bag)
    }

    private func showInfoBottomSheet(title: String, message: String) {
        infoRouter?.openInfoBottomSheet(title: title, message: message)
    }
}
