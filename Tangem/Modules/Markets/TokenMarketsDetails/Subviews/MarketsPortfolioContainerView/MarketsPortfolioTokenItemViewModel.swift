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

    @Published var stateView: MarketsPortfolioTokenItemView.StateTokenItem = .default
    @Published var fiatBalanceValue: String = ""
    @Published var balanceValue: String = ""
    @Published var contextActions: [TokenActionType] = []

    @Published var hasPendingTransactions: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

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

    private var bag = Set<AnyCancellable>()

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
        bind()
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, for: self)
    }

    // MARK: - Private Implementation

    private func bind() {
        tokenItemInfoProvider.tokenItemStatePublisher
            .receive(on: DispatchQueue.main)
            // We need this debounce to prevent initial sequential state updates that can skip `loading` state
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: MarketsPortfolioTokenItemViewModel.setupState(_:)))
            .store(in: &bag)

        tokenItemInfoProvider.actionsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.buildContextActions()
            }
            .store(in: &bag)
    }

    private func setupState(_ state: TokenItemViewState) {
        switch state {
        case .noDerivation:
            missingDerivation = true
            networkUnreachable = false
        case .networkError:
            missingDerivation = false
            networkUnreachable = true
        case .notLoaded:
            missingDerivation = false
            networkUnreachable = false
        case .loaded, .noAccount:
            missingDerivation = false
            networkUnreachable = false
        case .loading:
            break
        }

        updatePendingTransactionsStateIfNeeded()
        buildContextActions()
    }

    private func updatePendingTransactionsStateIfNeeded() {
        hasPendingTransactions = tokenItemInfoProvider.hasPendingTransactions
    }

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
