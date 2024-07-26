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
    @Published var fiatBalance: AttributedString = .init(BalanceFormatter.defaultEmptyBalanceString)
    @Published var cryptoBalance = ""

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    @Published var balanceTypeValues: [BalanceType]?
    @Published var selectedBalanceType: BalanceType = .all

    private let balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never>
    private let availableBalancePublisher: AnyPublisher<BalanceInfo?, Never>
    private let buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>

    private var bag = Set<AnyCancellable>()

    init(
        balanceProvider: BalanceProvider?,
        availableBalanceProvider: AvailableBalanceProvider?,
        buttonsProvider: ActionButtonsProvider?
    ) {
        balancePublisher = balanceProvider?.balancePublisher ?? Empty().eraseToAnyPublisher()
        availableBalancePublisher = availableBalanceProvider?.availableBalancePublisher
            ?? Empty().eraseToAnyPublisher()
        buttonsPublisher = buttonsProvider?.buttonsPublisher ?? Empty().eraseToAnyPublisher()
        bind()
    }

    private func bind() {
        Publishers.CombineLatest3(balancePublisher, availableBalancePublisher, $selectedBalanceType)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, state in
                let (balanceState, availableBalanceInfo, selectedBalanceType) = state
                switch balanceState {
                case .loading:
                    return
                case .loaded(let balanceInfo):
                    viewModel.updateBalances(
                        balanceInfo: balanceInfo,
                        availableBalanceInfo: availableBalanceInfo,
                        selectedBalanceType: selectedBalanceType
                    )
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load balance. Reason: \(error)")
                    viewModel.setupEmptyBalances()
                    viewModel.isLoadingFiatBalance = false
                }
                viewModel.balanceTypeValues = (availableBalanceInfo == nil) ? nil : BalanceType.allCases
                viewModel.isLoadingBalance = false
            })
            .store(in: &bag)

        buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)
    }

    private func setupEmptyBalances() {
        fiatBalance = .init(BalanceFormatter.defaultEmptyBalanceString)
        cryptoBalance = BalanceFormatter.defaultEmptyBalanceString
    }

    private func updateBalances(
        balanceInfo: BalanceInfo?,
        availableBalanceInfo: BalanceInfo?,
        selectedBalanceType: BalanceType
    ) {
        let formatter = BalanceFormatter()

        let displayBalanceInfo: BalanceInfo

        if selectedBalanceType == .all, let balanceInfo {
            displayBalanceInfo = balanceInfo
        } else if selectedBalanceType == .available, let availableBalanceInfo {
            displayBalanceInfo = availableBalanceInfo
        } else {
            AppLog.shared.debug("Attempt to display balances before they are loaded")
            return
        }

        isLoadingFiatBalance = false

        cryptoBalance = displayBalanceInfo.balance
        fiatBalance = formatter.formatAttributedTotalBalance(fiatBalance: displayBalanceInfo.fiatBalance)
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
