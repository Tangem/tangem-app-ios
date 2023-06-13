//
//  TotalSumBalanceViewModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 16.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class TotalSumBalanceViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoading: Bool = true
    @Published var totalFiatValueString: NSAttributedString = .init(string: "")
    @Published var hasError: Bool = false

    /// If we have a note or any single coin wallet that we should show this balance
    @Published var singleWalletBalance: String?

    // MARK: - Private

    @Injected(\.rateAppService) private var rateAppService: RateAppService
    private unowned let tapOnCurrencySymbol: OpenCurrencySelectionDelegate
    private let cardAmountType: Amount.AmountType?
    private let userWalletModel: UserWalletModel
    private var totalBalanceManager: TotalBalanceProviding { userWalletModel.totalBalanceProvider }

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        cardAmountType: Amount.AmountType?,
        tapOnCurrencySymbol: OpenCurrencySelectionDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.cardAmountType = cardAmountType
        self.tapOnCurrencySymbol = tapOnCurrencySymbol
        bind()
    }

    func updateForSingleCoinCard() {
        guard let cardAmountType = cardAmountType else { return }

        singleWalletBalance = userWalletModel.walletModels.first?.legacyMultiCurrencyViewModel().first(where: { $0.amountType == cardAmountType })?.balance
    }

    func didTapOnCurrencySymbol() {
        tapOnCurrencySymbol.openCurrencySelection()
    }

    private func bind() {
        totalBalanceManager.totalBalancePublisher()
            .compactMap { $0.value }
            .map { [unowned self] balance -> NSAttributedString in
                checkPositiveBalance()
                updateForSingleCoinCard()
                return addAttributeForBalance(balance)
            }
            .weakAssign(to: \.totalFiatValueString, on: self)
            .store(in: &bag)

        // Skeleton subscription
        totalBalanceManager.totalBalancePublisher()
            .map { $0.isLoading }
            .weakAssignAnimated(to: \.isLoading, on: self)
            .store(in: &bag)

        totalBalanceManager.totalBalancePublisher()
            .compactMap { $0.value?.hasError }
            .removeDuplicates()
            .weakAssign(to: \.hasError, on: self)
            .store(in: &bag)
    }

    private func addAttributeForBalance(_ totalValue: TotalBalanceProvider.TotalBalance) -> NSAttributedString {
        let balanceFormatter = BalanceFormatter()
        let formattedTotalFiatValue = balanceFormatter.formatFiatBalance(totalValue.balance, formattingOptions: .defaultFiatFormattingOptions)
        return balanceFormatter.formatTotalBalanceForMain(fiatBalance: formattedTotalFiatValue, formattingOptions: .defaultOptions)
    }

    private func checkPositiveBalance() {
        guard rateAppService.shouldCheckBalanceForRateApp else { return }

        guard userWalletModel.walletModels.contains(where: { !$0.wallet.isEmpty }) else { return }

        rateAppService.registerPositiveBalanceDate()
    }
}
