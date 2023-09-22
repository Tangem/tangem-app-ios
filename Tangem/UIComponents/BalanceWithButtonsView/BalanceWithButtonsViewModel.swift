//
//  BalanceWithButtonsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 31/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    @Published var isLoadingFiatBalance = true
    @Published var isLoadingBalance = true
    @Published var fiatBalance = NSAttributedString(string: "")
    @Published var cryptoBalance = ""

    @Published var buttons: [ButtonWithIconInfo] = []

    private weak var balanceProvider: BalanceProvider?
    private weak var buttonsProvider: ActionButtonsProvider?

    private var bag = Set<AnyCancellable>()

    init(balanceProvider: BalanceProvider?, buttonsProvider: ActionButtonsProvider?) {
        self.balanceProvider = balanceProvider
        self.buttonsProvider = buttonsProvider

        bind()
    }

    private func bind() {
        balanceProvider?.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] balanceState in
                switch balanceState {
                case .loading:
                    return
                case .loaded(let balance):
                    self?.updateBalances(for: balance)
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load balance. Reason: \(error)")
                    self?.setupEmptyBalances()
                    self?.isLoadingFiatBalance = false
                }
                self?.isLoadingBalance = false
            })
            .store(in: &bag)

        buttonsProvider?.buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)
    }

    private func setupEmptyBalances() {
        fiatBalance = .init(string: BalanceFormatter.defaultEmptyBalanceString)
        cryptoBalance = BalanceFormatter.defaultEmptyBalanceString
    }

    private func updateBalances(for newBalance: BalanceInfo) {
        let formatter = BalanceFormatter()

        isLoadingFiatBalance = false
        cryptoBalance = newBalance.balance
        fiatBalance = formatter.formatTotalBalanceForMain(fiatBalance: newBalance.fiatBalance, formattingOptions: .defaultOptions)
    }
}
