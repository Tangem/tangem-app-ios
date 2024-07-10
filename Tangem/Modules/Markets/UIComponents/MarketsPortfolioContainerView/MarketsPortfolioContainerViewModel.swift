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

    @Published var isShowAddButton: Bool = false
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

    // MARK: - Private Properties

    private let coinId: String
    private let walletDataSource: MarketsWalletDataSource
    private var addTapAction: (() -> Void)?

    // MARK: - Init

    init(walletDataSource: MarketsWalletDataSource, coinId: String, tokenItems: [TokenItem], addTapAction: (() -> Void)?) {
        self.coinId = coinId
        self.walletDataSource = walletDataSource
        self.addTapAction = addTapAction

        tokenItemViewModels = tokenItems.reduce(into: []) { partialResult, tokenItem in
            let tokenItemViewModelByUserWalletModels = walletDataSource.userWalletModels.map {
                MarketsPortfolioTokenItemViewModel(
                    userWalletModel: $0,
                    coinId: coinId,
                    tokenItem: tokenItem,
                    longPressTapAction: nil
                )
            }

            partialResult.append(contentsOf: tokenItemViewModelByUserWalletModels)
        }
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTapAction?()
    }

    // MARK: - Private Implementation

    private func initialSetup() {
        if walletDataSource.userWalletModels.isEmpty {}
    }
}
