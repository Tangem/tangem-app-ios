//
//  ManageTokensCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    weak var delegate: ManageTokensCoordinatorDelegate?

    // MARK: - Root Published

    @Published private(set) var manageTokensViewModel: ManageTokensViewModel? = nil

    // MARK: - Child ViewModels

    @Published var networkSelectorViewModel: ManageTokensNetworkSelectorViewModel? = nil
    @Published var walletSelectorViewModel: WalletSelectorViewModel? = nil
    @Published var addCustomTokenCoordinator: AddCustomTokenCoordinator?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: ManageTokensCoordinator.Options) {
        assert(delegate != nil)
        manageTokensViewModel = .init(searchTextPublisher: options.searchTextPublisher, coordinator: self)
    }
}

extension ManageTokensCoordinator {
    struct Options {
        let searchTextPublisher: AnyPublisher<String, Never>
    }
}

extension ManageTokensCoordinator: ManageTokensRoutable {
    func openAddCustomToken(dataSource: ManageTokensDataSource) {
        guard let userWalletModel = dataSource.defaultUserWalletModel else { return }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.addCustomTokenCoordinator = nil
        }

        let addCustomTokenCoordinator = AddCustomTokenCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        addCustomTokenCoordinator.start(with: .init(userWalletModel: userWalletModel, dataSource: dataSource))
        self.addCustomTokenCoordinator = addCustomTokenCoordinator
    }

    func openTokenSelector(dataSource: ManageTokensDataSource, coinId: String, tokenItems: [TokenItem]) {
        networkSelectorViewModel = ManageTokensNetworkSelectorViewModel(
            parentDataSource: dataSource,
            coinId: coinId,
            tokenItems: tokenItems,
            coordinator: self
        )
    }

    func showGenerateAddressesWarning(
        numberOfNetworks: Int,
        currentWalletNumber: Int,
        totalWalletNumber: Int,
        action: @escaping () -> Void
    ) {
        delegate?.showGenerateAddressesWarning(
            numberOfNetworks: numberOfNetworks,
            currentWalletNumber: currentWalletNumber,
            totalWalletNumber: totalWalletNumber,
            action: action
        )
    }

    func hideGenerateAddressesWarning() {
        delegate?.hideGenerateAddressesWarning()
    }
}

extension ManageTokensCoordinator: ManageTokensNetworkSelectorRoutable {
    func openWalletSelector(with dataSource: WalletSelectorDataSource) {
        walletSelectorViewModel = WalletSelectorViewModel(dataSource: dataSource)
    }
}
