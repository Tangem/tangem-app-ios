//
//  ActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    // MARK: - Child viewModel

    let tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    // MARK: - Private property

    private weak var coordinator: ActionButtonsBuyRoutable?

    init(
        coordinator: some ActionButtonsBuyRoutable,
        tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel
    ) {
        self.coordinator = coordinator
        self.tokenSelectorViewModel = tokenSelectorViewModel
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .onAppear:
            ActionButtonsAnalyticsService.trackScreenOpened(.buy)
        case .close:
            ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
            coordinator?.dismiss()
        case .didTapToken(let token):
            ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: token.symbol)
            openBuy(token)
        }
    }

    private func openBuy(_ token: ActionButtonsTokenSelectorItem) {
        if FeatureProvider.isAvailable(.onramp) {
            coordinator?.openOnramp(walletModel: token.walletModel)
        } else if let buyUrl = makeBuyUrl(from: token) {
            coordinator?.openBuyCrypto(at: buyUrl)
        }
    }

    private func makeBuyUrl(from token: ActionButtonsTokenSelectorItem) -> URL? {
        let buyUrl = exchangeService.getBuyUrl(
            currencySymbol: token.symbol,
            amountType: token.walletModel.amountType,
            blockchain: token.walletModel.blockchainNetwork.blockchain,
            walletAddress: token.walletModel.defaultAddress
        )

        return buyUrl
    }
}

// MARK: - Action

extension ActionButtonsBuyViewModel {
    enum Action {
        case onAppear
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
