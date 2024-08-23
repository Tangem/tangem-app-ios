//
//  TokenMarketsNetworkSelectorCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 21.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class MarketsTokenNetworkSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published var rootViewModel: MarketsTokensNetworkSelectorViewModel? = nil

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = MarketsTokensNetworkSelectorViewModel(
            coinModel: options.coinModel,
            walletDataProvider: options.walletDataProvider,
            coordinator: self
        )
    }
}

extension MarketsTokenNetworkSelectorCoordinator {
    struct Options {
        let coinModel: CoinModel
        let walletDataProvider: MarketsWalletDataProvider
    }
}

// MARK: - MarketsTokensNetworkRoutable

extension MarketsTokenNetworkSelectorCoordinator: MarketsTokensNetworkRoutable {
    func dissmis() {
        dismissAction(())
    }
}
