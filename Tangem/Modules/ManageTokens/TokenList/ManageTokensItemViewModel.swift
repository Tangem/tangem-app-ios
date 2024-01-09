//
//  ManageTokensItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensItemViewModel: Identifiable, ObservableObject {
    // MARK: - Injected Properties

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData
    @Published var priceHistory: [Double]? = nil
    @Published var action: Action
    @Published var isLoading: Bool

    // MARK: - Properties

    var id: String { coinModel.id }
    var imageURL: URL? { TokenIconURLBuilder().iconURL(id: coinModel.id, size: .large) }
    var name: String { coinModel.name }
    var symbol: String { coinModel.symbol }

    let coinModel: CoinModel
    let didTapAction: (Action, CoinModel) -> Void

    private var bag = Set<AnyCancellable>()

    private var percentFormatter = PercentFormatter()
    private var balanceFormatter = BalanceFormatter()

    // MARK: - Helpers

    var priceHistoryChangeType: ChangeSignType {
        guard
            let priceHistory,
            let firstValue = priceHistory.first,
            let lastValue = priceHistory.last
        else {
            return .positive
        }

        return ChangeSignType(from: Decimal(lastValue - firstValue))
    }

    // MARK: - Init

    init(
        coinModel: CoinModel,
        priceValue: String = "",
        priceChangeState: TokenPriceChangeView.State = .loading,
        priceHistory: [Double]? = nil,
        action: Action,
        state: State,
        didTapAction: @escaping (Action, CoinModel) -> Void
    ) {
        self.coinModel = coinModel
        self.priceValue = priceValue
        self.priceChangeState = priceChangeState
        self.priceHistory = priceHistory
        self.action = action
        isLoading = state == .loading
        self.didTapAction = didTapAction

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        tokenQuotesRepository.quotesPublisher.sink { [weak self] itemQuote in
            guard let self = self else { return }

            if let quote = itemQuote[coinModel.id] {
                updateView(by: quote)
            }

            return
        }
        .store(in: &bag)
    }

    private func updateView(by quote: TokenQuote) {
        guard priceValue.isEmpty || priceChangeState == .loading || priceChangeState == .noData else {
            return
        }

        priceChangeState = getPriceChangeState(by: quote)
        priceValue = balanceFormatter.formatFiatBalance(quote.price)
        priceHistory = quote.prices24h?.map { $0 }
    }

    private func getPriceChangeState(by quote: TokenQuote) -> TokenPriceChangeView.State {
        let signType = ChangeSignType(from: quote.change ?? 0)

        let percent = percentFormatter.percentFormat(value: quote.change ?? 0)
        return .loaded(signType: signType, text: percent)
    }
}

extension ManageTokensItemViewModel {
    enum Action {
        case add
        case edit
        case info
    }

    enum State {
        case loading
        case loaded
    }
}
