//
//  MarketsTokenDetailsMetricsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 10/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsTokenDetailsMetricsViewModel: ObservableObject {
    @Published var records: [MarketsTokenDetailsMetricsView.RecordInfo] = []

    private let notationFormatter: DefaultAmountNotationFormatter
    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?

    private let formattingOptions = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .default(roundingMode: .plain, scale: 0)
    )

    private let metrics: MarketsTokenDetailsMetrics
    private let cryptoCurrencyCode: String

    private var currencyCodeChangeSubscription: AnyCancellable?
    private lazy var fiatFormatter: NumberFormatter = BalanceFormatter().makeDefaultFiatFormatter(for: AppSettings.shared.selectedCurrencyCode, formattingOptions: formattingOptions)
    private let cryptoFormatter: NumberFormatter

    init(
        metrics: MarketsTokenDetailsMetrics,
        notationFormatter: DefaultAmountNotationFormatter,
        cryptoCurrencyCode: String,
        infoRouter: MarketsTokenDetailsBottomSheetRouter?
    ) {
        self.metrics = metrics
        self.notationFormatter = notationFormatter
        self.cryptoCurrencyCode = cryptoCurrencyCode
        self.infoRouter = infoRouter
        cryptoFormatter = BalanceFormatter().makeDefaultCryptoFormatter(for: cryptoCurrencyCode, formattingOptions: formattingOptions)

        setupRecords()
        bindToCurrencyCodeUpdate()
    }

    func showInfoBottomSheet(for type: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: type.title, message: type.infoDescription)
    }

    private func bindToCurrencyCodeUpdate() {
        currencyCodeChangeSubscription = AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.fiatFormatter = BalanceFormatter().makeDefaultFiatFormatter(for: newCurrencyCode, formattingOptions: viewModel.formattingOptions)
                viewModel.setupRecords()
            }
    }

    private func setupRecords() {
        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let formatter = BalanceFormatter()

        let emptyValue = BalanceFormatter.defaultEmptyBalanceString

        func formatFiatValue(_ value: Decimal?) -> String {
            guard let value, value > 0 else {
                return emptyValue
            }

            return formatter.formatFiatBalance(value, formattingOptions: formattingOptions)
        }

        func formatCryptoValue(_ value: Decimal?) -> String {
            formatter.formatCryptoBalance(value, currencyCode: cryptoCurrencyCode)
        }

        var rating = emptyValue
        if let marketRating = metrics.marketRating, marketRating > 0 {
            rating = formatter.formatCryptoBalance(Decimal(marketRating), currencyCode: "", formattingOptions: formattingOptions)
        }
        records = [
            .init(type: .marketCapitalization, recordData: notationFormatter.format(metrics.marketCap, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .marketRating, recordData: rating),
            .init(type: .tradingVolume, recordData: notationFormatter.format(metrics.volume24H, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .fullyDilutedValuation, recordData: notationFormatter.format(metrics.fullyDilutedValuation, notationFormatter: amountNotationFormatter, numberFormatter: fiatFormatter, addingSignPrefix: false)),
            .init(type: .circulatingSupply, recordData: notationFormatter.format(metrics.circulatingSupply, notationFormatter: amountNotationFormatter, numberFormatter: cryptoFormatter, addingSignPrefix: false)),
            .init(type: .totalSupply, recordData: notationFormatter.format(metrics.totalSupply, notationFormatter: amountNotationFormatter, numberFormatter: cryptoFormatter, addingSignPrefix: false)),
        ]
    }
}
