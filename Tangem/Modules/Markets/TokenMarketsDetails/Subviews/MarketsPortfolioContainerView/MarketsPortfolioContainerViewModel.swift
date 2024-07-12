//
//  MarketsPortfolioContainerViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioContainerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isShowTopAddButton: Bool = false
    @Published var typeView: MarketsPortfolioContainerView.TypeView = .empty
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

    // MARK: - Private Properties

    private let userWalletModels: [UserWalletModel]
    private let coinId: String
    private var addTapAction: (() -> Void)?

    // MARK: - Init

    init(
        userWalletModels: [UserWalletModel],
        coinId: String,
        addTapAction: (() -> Void)?
    ) {
        self.userWalletModels = userWalletModels
        self.addTapAction = addTapAction
        self.coinId = coinId

        initialSetup()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTapAction?()
    }

    // MARK: - Private Implementation

    private func initialSetup() {
        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                let filteredWalletModels = userWalletModel.walletModelsManager.walletModels.filter {
                    $0.tokenItem.id?.caseInsensitiveCompare(coinId) == .orderedSame
                }

                let viewModels = filteredWalletModels.map { walletModel in
                    return MarketsPortfolioTokenItemViewModel(walletName: userWalletModel.name, walletModel: walletModel)
                }

                partialResult.append(contentsOf: viewModels)
            }

        tokenItemViewModels = tokenItemViewModelByUserWalletModels

        let hasMultiCurrency = !userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }.isEmpty

        if hasMultiCurrency {
            isShowTopAddButton = !tokenItemViewModels.isEmpty
            typeView = tokenItemViewModels.isEmpty ? .empty : .list
        } else {
            isShowTopAddButton = false
            typeView = tokenItemViewModels.isEmpty ? .unavailable : .list
        }
    }
}
