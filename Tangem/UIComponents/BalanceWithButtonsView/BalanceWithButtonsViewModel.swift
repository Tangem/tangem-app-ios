//
//  BalanceWithButtonsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 31/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    @Published var isLoadingFiatBalance = true
    @Published var isLoadingBalance = true
    @Published var fiatBalance: AttributedString = .init(BalanceFormatter.defaultEmptyBalanceString)
    @Published var cryptoBalance = ""

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    @Published var balanceTypeValues: [BalanceType]?
    @Published var selectedBalanceType: BalanceType = .all {
        didSet {
            updateBalances()
        }
    }

    private var balance: BalanceInfo? {
        didSet {
            if balance != nil {
                updateBalances()
            } else {
                setupEmptyBalances()
            }
        }
    }

    private var availableBalance: BalanceInfo? {
        didSet {
            balanceTypeValues = (availableBalance == nil) ? nil : BalanceType.allCases
        }
    }

    private weak var balanceProvider: BalanceProvider?
    private weak var availableBalanceProvider: AvailableBalanceProvider?
    private weak var buttonsProvider: ActionButtonsProvider?

    private var bag = Set<AnyCancellable>()

    init(balanceProvider: BalanceProvider?, availableBalanceProvider: AvailableBalanceProvider?, buttonsProvider: ActionButtonsProvider?) {
        self.balanceProvider = balanceProvider
        self.availableBalanceProvider = availableBalanceProvider
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
                    self?.balance = balance
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load balance. Reason: \(error)")
                    self?.balance = nil
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

        availableBalanceProvider?.availableBalancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] availableBalance in
                self?.availableBalance = availableBalance
            })
            .store(in: &bag)
    }

    private func setupEmptyBalances() {
        fiatBalance = .init(BalanceFormatter.defaultEmptyBalanceString)
        cryptoBalance = BalanceFormatter.defaultEmptyBalanceString
    }

    private func updateBalances() {
        let formatter = BalanceFormatter()

        let balanceInfo: BalanceInfo

        if selectedBalanceType == .all, let balance {
            balanceInfo = balance
        } else if selectedBalanceType == .available, let availableBalance {
            balanceInfo = availableBalance
        } else {
            return
        }

        isLoadingFiatBalance = false

        cryptoBalance = balanceInfo.balance
        fiatBalance = formatter.formatAttributedTotalBalance(fiatBalance: balanceInfo.fiatBalance)
    }
}

extension BalanceWithButtonsViewModel {
    enum BalanceType: String, CaseIterable, Hashable, Identifiable {
        case all
        case available

        var title: String {
            rawValue.capitalized
        }

        var id: String {
            rawValue
        }
    }
}
