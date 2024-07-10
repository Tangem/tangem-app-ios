//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioTokenItemViewModel: ObservableObject {
    // MARK: - Published Properties

    let coinImageURL: URL?
    let symbol: String
    let networkName: String
    let walletName: String

    // MARK: - Private Properties

    private let walletModelId: UserWalletId
    private let tokenItem: TokenItem
    private let longPressTapAction: (() -> Void)?

    private let userTokensManager: UserTokensManager

    private var bag = Set<AnyCancellable>()

    // MARK: - Utils

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = CommonTokenPriceFormatter()

    // MARK: - Init

    init(userWalletModel: UserWalletModel, coinId: String, tokenItem: TokenItem, longPressTapAction: ((TokenItem) -> Void)?) {
        walletModelId = userWalletModel.userWalletId
        walletName = userWalletModel.config.cardName
        userTokensManager = userWalletModel.userTokensManager
        
        self.coinImageURL = IconURLBuilder().tokenIconURL(id: coinId)
    }
}
