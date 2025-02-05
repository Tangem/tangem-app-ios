//
//  BalanceWithButtonsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 31/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    @Published var cryptoBalance: LoadableTokenBalanceView.State = .loading()
    @Published var fiatBalance: LoadableTokenBalanceView.State = .loading()

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    @Published var balanceTypeValues: [BalanceType]?
    @Published var selectedBalanceType: BalanceType = .all

    private let buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>
    private let balanceProvider: BalanceWithButtonsViewModelBalanceProvider

    private var bag = Set<AnyCancellable>()

    init(
        buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>,
        balanceProvider: BalanceWithButtonsViewModelBalanceProvider
    ) {
        self.buttonsPublisher = buttonsPublisher
        self.balanceProvider = balanceProvider

        bind()
    }

    private func bind() {
        Publishers
            .CombineLatest3(
                balanceProvider.totalCryptoBalancePublisher,
                balanceProvider.availableCryptoBalancePublisher,
                $selectedBalanceType
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] all, available, type in
                self?.setupCryptoBalances(all: all, available: available, type: type)
            }
            .store(in: &bag)

        Publishers
            .CombineLatest3(
                balanceProvider.totalFiatBalancePublisher,
                balanceProvider.availableFiatBalancePublisher,
                $selectedBalanceType
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] all, available, type in
                self?.setupFiatBalances(all: all, available: available, type: type)
            }
            .store(in: &bag)

        buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)
    }

    private func setupCryptoBalances(
        all: FormattedTokenBalanceType,
        available: FormattedTokenBalanceType,
        type: BalanceType
    ) {
        balanceTypeValues = all == available ? nil : BalanceType.allCases

        switch cryptoBalance {
        case .loaded where all.isLoading || available.isLoading:
            // Do nothing. Ignore if we have value and new value is loading
            break
        default:
            let builder = LoadableTokenBalanceViewStateBuilder()
            cryptoBalance = builder.build(type: type == .all ? all : available)
        }
    }

    private func setupFiatBalances(
        all: FormattedTokenBalanceType,
        available: FormattedTokenBalanceType,
        type: BalanceType
    ) {
        switch fiatBalance {
        case .loaded where all.isLoading || available.isLoading:
            // Do nothing. Ignore if we have value and new value is loading
            break
        default:
            let builder = LoadableTokenBalanceViewStateBuilder()
            fiatBalance = builder.buildAttributedTotalBalance(type: type == .all ? all : available)
        }
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
