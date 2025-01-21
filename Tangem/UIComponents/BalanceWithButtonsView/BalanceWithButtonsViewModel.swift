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
    @Published var isLoadingBalance = true
    @Published var isLoadingFiatBalance = true

    @Published var cryptoBalance: LoadableTokenBalanceView.State = .loading()
    @Published var fiatBalance: LoadableTokenBalanceView.State = .loading()

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    @Published var balanceTypeValues: [BalanceType]?
    @Published var selectedBalanceType: BalanceType = .all

    private let balancesPublisher: AnyPublisher<LoadingValue<Balances>, Never>
    private let buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>

    private let formatter = BalanceFormatter()
    private var bag = Set<AnyCancellable>()

    init(
        balancesPublisher: AnyPublisher<LoadingValue<Balances>, Never>,
        buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>
    ) {
        self.balancesPublisher = balancesPublisher
        self.buttonsPublisher = buttonsPublisher

        bind()
    }

    private func bind() {
        Publishers
            .CombineLatest(balancesPublisher, $selectedBalanceType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balances, type in
                self?.setupBalances(balances: balances, type: type)
            }
            .store(in: &bag)

        buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)
    }

    private func setupEmptyBalances() {
        fiatBalance = .empty
        cryptoBalance = .empty
    }

    private func setupBalances(balances: LoadingValue<Balances>, type: BalanceType) {
        switch balances {
        case .loading:
            // Do nothing to avoid skeletons when PRT
            break

        case .loaded(let balances):
            isLoadingBalance = false
            isLoadingFiatBalance = false
            updateBalances(balances: balances, type: type)

        case .failedToLoad:
            isLoadingBalance = false
            isLoadingFiatBalance = false
            setupEmptyBalances()
        }
    }

    private func updateBalances(balances: Balances, type: BalanceType) {
        let hasChoose = balances.all != balances.available
        balanceTypeValues = hasChoose ? BalanceType.allCases : nil

        switch selectedBalanceType {
        case .all:
            cryptoBalance = .loaded(text: .string(balances.all.crypto))
            fiatBalance = .loaded(text: .attributed(formatter.formatAttributedTotalBalance(fiatBalance: balances.all.fiat)))
        case .available:
            cryptoBalance = .loaded(text: .string(balances.available.crypto))
            fiatBalance = .loaded(text: .attributed(formatter.formatAttributedTotalBalance(fiatBalance: balances.available.fiat)))
        }
    }
}

extension BalanceWithButtonsViewModel {
    struct Balances: Hashable {
        let all: WalletModel.BalanceFormatted
        let available: WalletModel.BalanceFormatted
    }

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
