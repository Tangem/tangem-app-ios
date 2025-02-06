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

    @Published private(set) var fiatBalanceState: LoadableTokenBalanceView.State = .loading()
    @Published private(set) var balanceState: LoadableTokenBalanceView.State = .loading()

    private var bag = Set<AnyCancellable>()

    init(model: ActionButtonsTokenSelectorItem) {
        self.model = model

        bind()
    }

    private func bind() {
        bindBalance(publisher: model.infoProvider.balanceTypePublisher) { [weak self] in
            self?.balanceState = $0
        }

        bindBalance(publisher: model.infoProvider.fiatBalanceTypePublisher) { [weak self] in
            self?.fiatBalanceState = $0
        }
    }

    private func bindBalance<P: Publisher>(
        publisher: P,
        stateUpdate: @escaping (LoadableTokenBalanceView.State) -> Void
    ) where P.Output == FormattedTokenBalanceType, P.Failure == Never {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { balanceType in
                stateUpdate(LoadableTokenBalanceViewStateBuilder().build(type: balanceType))
            }
            .store(in: &bag)
    }
}

// MARK: - UI Properties

extension ActionButtonsTokenSelectItemViewModel {
    private var isLoading: Bool {
        balanceState == .loading() || fiatBalanceState == .loading()
    }

    var isDisabled: Bool {
        model.isDisabled || isLoading
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
