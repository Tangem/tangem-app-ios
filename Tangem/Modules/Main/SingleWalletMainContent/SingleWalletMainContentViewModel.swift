//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class SingleWalletMainContentViewModel: SingleTokenBaseViewModel, ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let singleWalletCoordinator: SingleWalletMainContentRoutable

    private var updateSubscription: AnyCancellable?

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        userTokensManager: UserTokensManager,
        exchangeUtility: ExchangeCryptoUtility,
        coordinator: SingleWalletMainContentRoutable
    ) {
        singleWalletCoordinator = coordinator

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            userTokensManager: userTokensManager,
            exchangeUtility: exchangeUtility,
            coordinator: coordinator
        )
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateSubscription == nil else {
            return
        }

        isReloadingTransactionHistory = true
        updateSubscription = walletModel.generalUpdate(silent: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.isReloadingTransactionHistory = false
                completionHandler()
                self?.updateSubscription = nil
            })
    }
}
