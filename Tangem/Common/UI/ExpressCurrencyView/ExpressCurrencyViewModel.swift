//
//  ExpressCurrencyViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

final class ExpressCurrencyViewModel: ObservableObject, Identifiable {
    // Header view
    @Published private(set) var titleState: TitleState
    @Published private(set) var balanceState: BalanceState

    // Bottom fiat
    @Published private(set) var fiatAmountState: LoadableTextView.State
    @Published private(set) var priceChangeState: PriceChangeState?

    // Trailing
    @Published private(set) var tokenIconState: TokenIconState
    @Published private(set) var symbolState: LoadableTextView.State
    @Published private(set) var canChangeCurrency: Bool

    private var walletDidChangeSubscription: AnyCancellable?
    private var highPriceTask: Task<Void, Error>?
    private var balanceConvertTask: Task<Void, Error>?

    init(
        titleState: TitleState,
        balanceState: BalanceState = .idle,
        fiatAmountState: LoadableTextView.State = .initialized,
        priceChangeState: PriceChangeState? = nil,
        tokenIconState: TokenIconState = .loading,
        symbolState: LoadableTextView.State = .loading,
        canChangeCurrency: Bool
    ) {
        self.titleState = titleState
        self.balanceState = balanceState
        self.fiatAmountState = fiatAmountState
        self.priceChangeState = priceChangeState
        self.tokenIconState = tokenIconState
        self.symbolState = symbolState
        self.canChangeCurrency = canChangeCurrency
    }

    func update(wallet: LoadingValue<WalletModel>, initialWalletId: WalletModelId) {
        switch wallet {
        case .loading:
            canChangeCurrency = false
            tokenIconState = .loading
            symbolState = .loading
            balanceState = .loading
        case .loaded(let wallet):
            canChangeCurrency = wallet.id != initialWalletId
            tokenIconState = .icon(TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom))
            symbolState = .loaded(text: wallet.tokenItem.currencySymbol)

            walletDidChangeSubscription = wallet.availableBalanceProvider.balanceTypePublisher.sink { [weak self] state in
                switch state {
                case .loading:
                    self?.balanceState = .loading
                case .loaded(let balance):
                    let formatted = BalanceFormatter().formatDecimal(balance)
                    self?.balanceState = .formatted(formatted)
                // No balance cases
                case .empty, .failure:
                    self?.balanceState = .formatted(BalanceFormatter.defaultEmptyBalanceString)
                }
            }
        case .failedToLoad:
            canChangeCurrency = true
            tokenIconState = .notAvailable
            symbolState = .noData
            balanceState = .notAvailable
        }
    }

    func updateFiatValue(expectAmount: Decimal?, tokenItem: TokenItem?) {
        guard let expectAmount else {
            update(fiatAmountState: .loaded(text: BalanceFormatter().formatFiatBalance(0)))
            return
        }

        guard let currencyId = tokenItem?.currencyId else {
            update(fiatAmountState: .loaded(text: BalanceFormatter().formatFiatBalance(0)))
            return
        }

        if let fiatValue = BalanceConverter().convertToFiat(expectAmount, currencyId: currencyId) {
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            update(fiatAmountState: .loaded(text: formatted))
            return
        }

        update(fiatAmountState: .loading)

        balanceConvertTask?.cancel()
        balanceConvertTask = runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await BalanceConverter().convertToFiat(expectAmount, currencyId: currencyId)
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)

            try Task.checkCancellation()

            await runOnMain {
                viewModel.update(fiatAmountState: .loaded(text: formatted))
            }
        }
    }

    func updateHighPricePercentLabel(quote: ExpressQuote?, sourceCurrencyId: String?, destinationCurrencyId: String?) {
        guard let fromAmount = quote?.fromAmount,
              let expectAmount = quote?.expectAmount,
              let sourceCurrencyId,
              let destinationCurrencyId else {
            priceChangeState = nil
            return
        }

        highPriceTask?.cancel()
        highPriceTask = runTask(in: self) { viewModel in
            let priceImpactCalculator = HighPriceImpactCalculator(sourceCurrencyId: sourceCurrencyId, destinationCurrencyId: destinationCurrencyId)
            let result = try await priceImpactCalculator.isHighPriceImpact(
                converting: fromAmount,
                to: expectAmount
            )

            guard result.isHighPriceImpact else {
                await runOnMain {
                    viewModel.priceChangeState = .info
                }
                return
            }

            let percentFormatter = PercentFormatter()
            let formatted = percentFormatter.format(-result.lossesInPercents, option: .express)
            await runOnMain {
                viewModel.priceChangeState = .percent(formatted)
            }
        }
    }

    func update(titleState: TitleState) {
        self.titleState = titleState
    }

    func update(fiatAmountState: LoadableTextView.State) {
        self.fiatAmountState = fiatAmountState
    }
}

extension ExpressCurrencyViewModel {
    enum PriceChangeState: Hashable {
        case info
        case percent(_ formatted: String)
    }

    enum TitleState: Hashable {
        case text(String)
        case insufficientFunds
        case error(String)
    }

    enum BalanceState: Hashable {
        case idle
        case notAvailable
        case loading
        case formatted(String)
    }

    enum TokenIconState: Hashable {
        case loading
        case notAvailable
        case icon(TokenIconInfo)
    }
}
