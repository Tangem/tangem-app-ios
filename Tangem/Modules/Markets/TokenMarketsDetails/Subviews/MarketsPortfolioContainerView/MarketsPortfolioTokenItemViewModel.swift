//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioTokenItemViewModel: ObservableObject, Identifiable {
    // MARK: - Public Properties

    @Published var fiatBalanceValue: String = ""
    @Published var balanceValue: String = ""
    @Published var contextActions: [TokenActionType] = []

    var id: Int {
        hashValue
    }

    var tokenIconInfo: TokenIconInfo {
        TokenIconInfoBuilder().build(from: tokenItemInfoProvider.tokenItem, isCustom: false)
    }

    var tokenName: String {
        tokenItemInfoProvider.tokenItem.networkName
    }

    let userWalletId: UserWalletId
    let walletName: String

    let tokenItemInfoProvider: TokenItemInfoProvider

    // MARK: - Private Properties

    private weak var contextActionsProvider: MarketsPortfolioContextActionsProvider?
    private weak var contextActionsDelegate: MarketsPortfolioContextActionsDelegate?

    private var updateSubscription: AnyCancellable?

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        walletName: String,
        tokenItemInfoProvider: TokenItemInfoProvider,
        contextActionsProvider: MarketsPortfolioContextActionsProvider?,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate?
    ) {
        self.userWalletId = userWalletId
        self.walletName = walletName
        self.tokenItemInfoProvider = tokenItemInfoProvider
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate

        buildContextActions()
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, for: self)
    }

    // MARK: - Private Implementation

    private func buildContextActions() {
        contextActions = contextActionsProvider?.buildContextActions(for: self) ?? []
    }
}

extension MarketsPortfolioTokenItemViewModel: Hashable {
    static func == (lhs: MarketsPortfolioTokenItemViewModel, rhs: MarketsPortfolioTokenItemViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userWalletId)
        hasher.combine(tokenItemInfoProvider.id)
    }
}
