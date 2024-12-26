//
//  TokenItemViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk

protocol TokenItemContextActionsProvider: AnyObject {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection]
}

protocol TokenItemContextActionDelegate: AnyObject {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: TokenItemViewModel)
}

final class TokenItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId

    @Published var balanceCrypto: LoadableTokenBalanceView.State = .loading()
    @Published var balanceFiat: LoadableTokenBalanceView.State = .loading()
    @Published var priceChangeState: TokenPriceChangeView.State = .loading
    @Published var tokenPrice: LoadableTextView.State = .loading
    @Published var hasPendingTransactions: Bool = false
    @Published var contextActionSections: [TokenContextActionsSection] = []
    @Published var isStaked: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation || isTestnetToken }
    var isCustom: Bool { tokenIcon.isCustom }
    var customTokenColor: Color? { tokenIcon.customTokenColor }
    var tokenItem: TokenItem { infoProvider.tokenItem }

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

    private let tokenIcon: TokenIconInfo
    private let isTestnetToken: Bool
    private let tokenTapped: (WalletModelId) -> Void
    private let infoProvider: TokenItemInfoProvider
    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = TokenItemPriceFormatter()

    private var bag = Set<AnyCancellable>()
    private weak var contextActionsProvider: TokenItemContextActionsProvider?
    private weak var contextActionsDelegate: TokenItemContextActionDelegate?

    init(
        id: WalletModelId,
        tokenIcon: TokenIconInfo,
        isTestnetToken: Bool,
        infoProvider: TokenItemInfoProvider,
        tokenTapped: @escaping (WalletModelId) -> Void,
        contextActionsProvider: TokenItemContextActionsProvider,
        contextActionsDelegate: TokenItemContextActionDelegate
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.isTestnetToken = isTestnetToken
        self.infoProvider = infoProvider
        self.tokenTapped = tokenTapped
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate

        setupView(infoProvider.balance)
        bind()
    }

    func tapAction() {
        tokenTapped(id)
    }

    func didTapContextAction(_ actionType: TokenActionType) {
        contextActionsDelegate?.didTapContextAction(actionType, for: self)
    }

    private func bind() {
        infoProvider.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupView(type)
            })
            .store(in: &bag)

        infoProvider
            .balanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupBalance(type)
            })
            .store(in: &bag)

        infoProvider
            .fiatBalanceTypePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupFiatBalance(type)
            })
            .store(in: &bag)

        infoProvider
            .quotePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] type in
                self?.setupPrice(type)
            })
            .store(in: &bag)

        infoProvider.actionsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.buildContextActions()
            }
            .store(in: &bag)

        infoProvider.isStakedPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isStaked, on: self, ownership: .weak)
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

    private func setupPrice(_ quote: TokenQuote?) {
        guard let quote else {
            tokenPrice = .noData
            priceChangeState = .empty
            return
        }

        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: quote.priceChange24h)

        let priceText = priceFormatter.formatPrice(quote.price)
        tokenPrice = .loaded(text: priceText)
    }

    private func updatePendingTransactionsStateIfNeeded() {
        hasPendingTransactions = infoProvider.hasPendingTransactions
    }

    private func buildContextActions() {
        contextActionSections = contextActionsProvider?.buildContextActions(for: self) ?? []
    }
}
