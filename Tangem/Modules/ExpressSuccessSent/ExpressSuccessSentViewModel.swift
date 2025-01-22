//
//  ExpressSuccessSentViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress

final class ExpressSuccessSentViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var sourceData: AmountSummaryViewData?
    @Published var destinationData: AmountSummaryViewData?
    @Published var provider: ProviderRowViewModel?
    @Published var expressFee: ExpressFeeRowData?

    var isStatusButtonVisible: Bool {
        data.expressTransactionData.externalTxUrl != nil
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        return formatter.string(from: data.date)
    }

    // MARK: - Dependencies

    private let data: SentExpressTransactionData
    private let initialWallet: WalletModel
    private let balanceConverter: BalanceConverter
    private let balanceFormatter: BalanceFormatter
    private let providerFormatter: ExpressProviderFormatter
    private let feeFormatter: FeeFormatter
    private weak var coordinator: ExpressSuccessSentRoutable?

    init(
        data: SentExpressTransactionData,
        initialWallet: WalletModel,
        balanceConverter: BalanceConverter,
        balanceFormatter: BalanceFormatter,
        providerFormatter: ExpressProviderFormatter,
        feeFormatter: FeeFormatter,
        coordinator: ExpressSuccessSentRoutable
    ) {
        self.data = data
        self.initialWallet = initialWallet
        self.balanceConverter = balanceConverter
        self.balanceFormatter = balanceFormatter
        self.providerFormatter = providerFormatter
        self.feeFormatter = feeFormatter
        self.coordinator = coordinator

        setupView()
        Analytics.log(
            event: .swapSwapInProgressScreenOpened,
            params: [
                .provider: data.provider.name,
                .commission: data.feeOption.rawValue.capitalizingFirstLetter(),
                .sendToken: data.source.tokenItem.currencySymbol,
                .receiveToken: data.destination.tokenItem.currencySymbol,
                .sendBlockchain: data.source.tokenItem.blockchain.displayName,
                .receiveBlockchain: data.destination.tokenItem.blockchain.displayName,
            ]
        )
    }

    func openExplore() {
        guard let exploreURL = data.source.exploreTransactionURL(for: data.hash) else {
            return
        }

        Analytics.log(event: .swapButtonExplore, params: [.token: initialWallet.tokenItem.currencySymbol])
        coordinator?.openWebView(url: exploreURL)
    }

    func openCEXStatus() {
        guard let externalTxUrl = data.expressTransactionData.externalTxUrl.map(URL.init(string:)) else {
            return
        }

        Analytics.log(event: .swapButtonStatus, params: [.token: initialWallet.tokenItem.currencySymbol])
        coordinator?.openWebView(url: externalTxUrl)
    }

    func closeView() {
        coordinator?.close()
    }
}

private extension ExpressSuccessSentViewModel {
    func setupView() {
        let fromAmount = data.expressTransactionData.fromAmount
        let toAmount = data.expressTransactionData.toAmount
        let sourceTokenItem = data.source.tokenItem
        let destinationTokenItem = data.destination.tokenItem

        let sourceAmountFormatted = balanceFormatter.formatCryptoBalance(fromAmount, currencyCode: sourceTokenItem.currencySymbol)
        let sourceFiatAmount = balanceConverter.convertToFiat(fromAmount, currencyId: sourceTokenItem.currencyId ?? "")
        let sourceFiatAmountFormatted = balanceFormatter.formatFiatBalance(sourceFiatAmount)

        sourceData = AmountSummaryViewData(
            title: Localization.swappingFromTitle,
            amount: sourceAmountFormatted,
            amountFiat: sourceFiatAmountFormatted,
            tokenIconInfo: TokenIconInfoBuilder().build(from: sourceTokenItem, isCustom: false)
        )

        let destinationAmountFormatted = balanceFormatter.formatCryptoBalance(toAmount, currencyCode: destinationTokenItem.currencySymbol)
        let destinationFiatAmount = balanceConverter.convertToFiat(toAmount, currencyId: destinationTokenItem.currencyId ?? "")
        let destinationFiatAmountFormatted = balanceFormatter.formatFiatBalance(destinationFiatAmount)

        destinationData = AmountSummaryViewData(
            title: Localization.swappingToTitle,
            amount: destinationAmountFormatted,
            amountFiat: destinationFiatAmountFormatted,
            tokenIconInfo: TokenIconInfoBuilder().build(from: destinationTokenItem, isCustom: false)
        )

        let subtitle = providerFormatter.mapToRateSubtitle(
            fromAmount: fromAmount,
            toAmount: toAmount,
            senderCurrencyCode: sourceTokenItem.currencySymbol,
            destinationCurrencyCode: destinationTokenItem.currencySymbol,
            option: .exchangeRate
        )

        provider = ProviderRowViewModel(
            provider: providerFormatter.mapToProvider(provider: data.provider),
            titleFormat: .name,
            isDisabled: false,
            badge: .none,
            subtitles: [subtitle],
            detailsType: .none
        )

        let feeFormatted = feeFormatter.format(fee: data.fee, tokenItem: data.source.feeTokenItem)
        expressFee = ExpressFeeRowData(title: Localization.commonNetworkFeeTitle, subtitle: .loaded(text: feeFormatted))
    }
}
