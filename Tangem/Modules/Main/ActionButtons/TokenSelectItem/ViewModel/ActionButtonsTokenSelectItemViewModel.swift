//
//  ActionButtonsTokenSelectItemViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 21.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class ActionButtonsTokenSelectItemViewModel: ObservableObject {
    private let model: ActionButtonsTokenSelectorItem

    @Published private(set) var fiatBalanceState: LoadableTextView.State = .loading
    @Published private(set) var balanceState: LoadableTextView.State = .loading

    private var itemStateBag: AnyCancellable?

    init(model: ActionButtonsTokenSelectorItem) {
        self.model = model

        bind()
    }

    private func bind() {
        itemStateBag = model.infoProvider.tokenItemStatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, newState in
                switch newState {
                case .loading:
                    viewModel.updateBalances(to: .loading)
                case .loaded:
                    viewModel.fiatBalanceState = .loaded(text: viewModel.model.infoProvider.fiatBalance)
                    viewModel.balanceState = .loaded(text: viewModel.model.infoProvider.balance)
                default:
                    viewModel.updateBalances(to: .noData)
                }
            }
    }

    private func updateBalances(to state: LoadableTextView.State) {
        fiatBalanceState = state
        balanceState = state
    }
}

// MARK: - UI Properties

extension ActionButtonsTokenSelectItemViewModel {
    var isDisabled: Bool {
        model.infoProvider.tokenItemState == .loading || model.isDisabled
    }

    var tokenIconInfo: TokenIconInfo {
        model.tokenIconInfo
    }

    var tokenName: String {
        model.tokenIconInfo.name
    }

    var currencySymbol: String {
        model.infoProvider.tokenItem.currencySymbol
    }

    func getDisabledTextColor(for item: TextItem) -> Color {
        switch item {
        case .tokenName, .fiatBalance:
            model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
        case .balance:
            model.isDisabled ? Colors.Text.disabled : Colors.Text.tertiary
        }
    }

    enum TextItem {
        case tokenName
        case balance
        case fiatBalance
    }
}
