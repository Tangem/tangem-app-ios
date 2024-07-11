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
    private let tokenItems: [TokenItem]
    private var addTapAction: (() -> Void)?

    // MARK: - Init

    init(
        userWalletModels: [UserWalletModel],
        tokenItems: [TokenItem],
        addTapAction: (() -> Void)?
    ) {
        self.userWalletModels = userWalletModels
        self.addTapAction = addTapAction
        self.tokenItems = tokenItems

        initialSetup()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTapAction?()
    }

    // MARK: - Private Implementation

    private func initialSetup() {
        tokenItemViewModels = tokenItems.reduce(into: []) { partialResult, tokenItem in
            let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
                .compactMap { userWalletModel in
                    guard
                        userWalletModel.userTokensManager.contains(tokenItem),
                        let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.tokenItem == tokenItem })
                    else {
                        return nil
                    }

                    let inputData = MarketsPortfolioTokenItemViewModel.InputData(
                        coinImageURL: IconURLBuilder().tokenIconURL(optionalId: tokenItem.id),
                        walletName: userWalletModel.config.cardName,
                        tokenName: "\(tokenItem.currencySymbol) \(tokenItem.networkName)",
                        fiatBalanceValue: walletModel.fiatBalance,
                        balanceValue: walletModel.balance,
                        userWalletId: userWalletModel.userWalletId,
                        tokenItemId: tokenItem.id
                    )

                    return MarketsPortfolioTokenItemViewModel(data: inputData)
                }

            partialResult.append(contentsOf: tokenItemViewModelByUserWalletModels)
        }

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
