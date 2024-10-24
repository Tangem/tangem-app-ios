//
//  MarketsTokenNetworkSelectorCoordinator.swift
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

    // MARK: - Child ViewModels

    @Published var walletSelectorViewModel: WalletSelectorViewModel?

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
            data: options.inputData,
            walletDataProvider: options.walletDataProvider,
            coordinator: self
        )
    }
}

extension MarketsTokenNetworkSelectorCoordinator {
    struct Options {
        let inputData: MarketsTokensNetworkSelectorViewModel.InputData
        let walletDataProvider: MarketsWalletDataProvider
    }
}

// MARK: - MarketsTokensNetworkRoutable

extension MarketsTokenNetworkSelectorCoordinator: MarketsTokensNetworkRoutable, WalletSelectorRoutable {
    func openWalletSelector(with provider: MarketsWalletDataProvider) {
        let walletSelectorViewModel = WalletSelectorViewModel(dataSource: provider, coordinator: self)
        self.walletSelectorViewModel = walletSelectorViewModel
    }

    func dissmisWalletSelectorModule() {
        walletSelectorViewModel = nil
    }

    func dissmis() {
        dismissAction(())
    }
}
