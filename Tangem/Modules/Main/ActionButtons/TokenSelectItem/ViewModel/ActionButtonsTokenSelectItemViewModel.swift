//
//  ActionButtonsTokenSelectItemViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 21.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class ActionButtonsTokenSelectItemViewModel: ObservableObject {
    let model: ActionButtonsTokenSelectorItem

    @Published private(set) var fiatBalanceState: LoadableTextView.State = .loading
    @Published private(set) var balanceState: LoadableTextView.State = .loading

    var isDisabled: Bool {
        model.infoProvider.tokenItemState == .loading || model.isDisabled
    }

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
