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

    @Published var balanceCrypto: LoadableTokenBalanceView.State = .loading()
    @Published var balanceFiat: LoadableTokenBalanceView.State = .loading()
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
        setupView(tokenItemInfoProvider.balance)
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
        tokenItemInfoProvider
            .balancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupView(type)
            })
            .store(in: &bag)

        tokenItemInfoProvider
            .balanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupBalance(type)
            })
            .store(in: &bag)

        tokenItemInfoProvider
            .fiatBalanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupFiatBalance(type)
            })
            .store(in: &bag)

        tokenItemInfoProvider
            .actionsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.buildContextActions()
            }
            .store(in: &bag)
    }

    private func setupView(_ type: TokenBalanceType) {
        switch type {
        case .empty(.noDerivation):
            missingDerivation = true
        default:
            missingDerivation = false
        }

        updatePendingTransactionsStateIfNeeded()
        buildContextActions()
    }

    private func setupBalance(_ type: FormattedTokenBalanceType) {
        balanceCrypto = LoadableTokenBalanceViewStateBuilder().build(type: type)
    }

    private func setupFiatBalance(_ type: FormattedTokenBalanceType) {
        balanceFiat = LoadableTokenBalanceViewStateBuilder().build(type: type, icon: .leading)
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
}
