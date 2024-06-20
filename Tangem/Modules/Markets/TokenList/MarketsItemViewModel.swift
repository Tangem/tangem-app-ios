//
//  MarketsItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsItemViewModel: Identifiable, ObservableObject {
    // MARK: - Published

    @Published var isLoading: Bool

    @Published var marketRating: String?
    @Published var marketCap: String?

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData

    // Charts will be implement in https://tangem.atlassian.net/browse/IOS-6775
    @Published var charts: [Double]? = nil

    // MARK: - Properties

    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private let priceChangeFormatter = PriceChangeFormatter()
    private let priceFormatter = CommonTokenPriceFormatter()
    private let marketCapFormatter = CommonMarketCapFormatter()

    // MARK: - Init

    init(_ data: InputData) {
        isLoading = data.isLoading

        id = data.id
        imageURL = IconURLBuilder().tokenIconURL(id: id, size: .large)
        name = data.name
        symbol = data.symbol.uppercased()

        if let marketRating = data.marketRating {
            self.marketRating = "\(marketRating)"
        }

        if let marketCap = data.marketCap {
            self.marketCap = marketCapFormatter.formatDecimal(Decimal(marketCap))
        }

        priceValue = priceFormatter.formatFiatBalance(data.priceValue)

        if let priceChangeStateValue = data.priceChangeStateValue {
            let priceChangeResult = priceChangeFormatter.format(priceChangeStateValue * Constants.priceChangeStateValueDevider, option: .priceChange)
            priceChangeState = .loaded(signType: priceChangeResult.signType, text: priceChangeResult.formattedText)
        } else {
            priceChangeState = .loading
        }

        charts = data.charts

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        // Need for user update charts
    }
}

extension MarketsItemViewModel {
    struct InputData {
        let id: String
        let name: String
        let symbol: String
        let marketCap: UInt64?
        let marketRating: UInt64?
        let priceValue: Decimal?
        let priceChangeStateValue: Decimal?
        let charts: [Double]?
        let isLoading: Bool
    }

    enum Constants {
        static let priceChangeStateValueDevider: Decimal = 0.01
    }
}
