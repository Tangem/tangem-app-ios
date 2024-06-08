//
//  MarketsCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    weak var delegate: MarketsCoordinatorDelegate?

    // MARK: - Root Published

    @Published private(set) var manageTokensViewModel: MarketsViewModel? = nil

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

    func start(with options: MarketsCoordinator.Options) {
        assert(delegate != nil)
        manageTokensViewModel = .init(searchTextPublisher: options.searchTextPublisher, coordinator: self)
    }

    func onBottomScrollableSheetStateChange(_ state: BottomScrollableSheetState) {
        if state.isBottom {
            manageTokensViewModel?.onBottomDisappear()
        } else {
            manageTokensViewModel?.onBottomAppear()
        }
    }
}

extension MarketsCoordinator {
    struct Options {
        let searchTextPublisher: AnyPublisher<String, Never>
    }
}

extension MarketsCoordinator: MarketsRoutable {
    func openAddCustomToken(dataSource: MarketsDataSource) {
        guard let userWalletModel = dataSource.defaultUserWalletModel else { return }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.addCustomTokenCoordinator = nil
            self?.dismiss()
        }

        let addCustomTokenCoordinator = AddCustomTokenCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        addCustomTokenCoordinator.start(with: .init(userWalletModel: userWalletModel, dataSource: dataSource))
        self.addCustomTokenCoordinator = addCustomTokenCoordinator
    }

    func openTokenSelector(dataSource: MarketsDataSource, coinId: String, tokenItems: [TokenItem]) {
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

extension MarketsCoordinator: ManageTokensNetworkSelectorRoutable {
    func openWalletSelector(with dataSource: WalletSelectorDataSource) {
        walletSelectorViewModel = WalletSelectorViewModel(dataSource: dataSource)
    }
}
