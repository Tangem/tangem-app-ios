//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class MarketsPortfolioTokenItemViewModel: ObservableObject, Identifiable {
    // MARK: - Public Properties

    @Published var balanceCrypto: LoadableTextView.State = .loading
    @Published var balanceFiat: LoadableTextView.State = .loading
    @Published var contextActions: [TokenActionType] = []

    @Published var hasPendingTransactions: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation }
    var isCustom: Bool { tokenIcon.isCustom }
    var customTokenColor: Color? { tokenIcon.customTokenColor }
    var tokenItem: TokenItem { tokenItemInfoProvider.tokenItem }

    var hasError: Bool { missingDerivation || networkUnreachable }

    var errorMessage: String? {
        // Don't forget to add check in trailing item in `TokenItemView` when adding new error here
        if missingDerivation {
            return Localization.commonNoAddress
        }

        if networkUnreachable {
            return Localization.commonUnreachable
        }

        return nil
    }

    let id = UUID()
    let userWalletId: UserWalletId
    let walletName: String

    let tokenIcon: TokenIconInfo
    let tokenItemInfoProvider: TokenItemInfoProvider

    // MARK: - Private Properties

    private weak var contextActionsProvider: MarketsPortfolioContextActionsProvider?
    private weak var contextActionsDelegate: MarketsPortfolioContextActionsDelegate?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        walletName: String,
        tokenIcon: TokenIconInfo,
        tokenItemInfoProvider: TokenItemInfoProvider,
        contextActionsProvider: MarketsPortfolioContextActionsProvider?,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate?
    ) {
        self.userWalletId = userWalletId
        self.walletName = walletName
        self.tokenIcon = tokenIcon
        self.tokenItemInfoProvider = tokenItemInfoProvider
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate

        bind()
        setupState(tokenItemInfoProvider.tokenItemState)
    }

    func showContextActions() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        contextActionsDelegate?.showContextAction(for: self)
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, walletModelId: tokenItemInfoProvider.id, userWalletId: userWalletId)
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
            updateBalances()
        case .networkError:
            missingDerivation = false
            networkUnreachable = true
        case .notLoaded:
            missingDerivation = false
            networkUnreachable = false
        case .loaded, .noAccount:
            missingDerivation = false
            networkUnreachable = false
            updateBalances()
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
        contextActions = contextActionsProvider?.buildContextActions(
            tokenItem: tokenItem,
            walletModelId: tokenItemInfoProvider.id,
            userWalletId: userWalletId
        ) ?? []
    }

    private func updateBalances() {
        balanceCrypto = .loaded(text: tokenItemInfoProvider.balance)
        balanceFiat = .loaded(text: tokenItemInfoProvider.fiatBalance)
    }
}
