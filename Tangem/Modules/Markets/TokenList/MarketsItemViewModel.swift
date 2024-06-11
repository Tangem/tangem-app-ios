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

    @Published var marketRating: String = ""
    @Published var marketCap: String = ""

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

    // MARK: - Init

    init(_ data: InputData) {
        id = data.id
        imageURL = URL(string: data.imageURL)
        name = data.name
        symbol = data.symbol

        marketCap = data.marketCap
        marketRating = data.marketRating

        priceValue = priceFormatter.formatFiatBalance(data.priceValue)

        if let priceChangeStateValue = data.priceChangeStateValue {
            let priceChangeResult = priceChangeFormatter.format(priceChangeStateValue, option: .priceChange)
            priceChangeState = .loaded(signType: priceChangeResult.signType, text: priceChangeResult.formattedText)
        } else {
            priceChangeState = .loading
        }

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
        let imageURL: String
        let name: String
        let symbol: String
        let marketCap: String
        let marketRating: String
        let priceValue: Decimal?
        let priceChangeStateValue: Decimal?
    }
}
