//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioTokenItemViewModel: ObservableObject, Identifiable {
    // MARK: - Published Properties

    let id: UUID = .init()

    let coinImageURL: URL?
    let walletName: String
    let tokenName: String
    let tokenImageName: String?

    let fiatBalanceValue: String
    let balanceValue: String

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let tokenItemId: TokenItemId?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(data: InputData) {
        coinImageURL = data.coinImageURL
        walletName = data.walletName
        tokenName = data.tokenName
        tokenImageName = data.tokenImageName
        fiatBalanceValue = data.fiatBalanceValue
        balanceValue = data.balanceValue
        userWalletId = data.userWalletId
        tokenItemId = data.tokenItemId
    }
}

extension MarketsPortfolioTokenItemViewModel {
    struct InputData {
        let coinImageURL: URL?
        let walletName: String
        let tokenName: String
        let tokenImageName: String?
        let fiatBalanceValue: String
        let balanceValue: String
        let userWalletId: UserWalletId
        let tokenItemId: TokenItemId?
    }
}
