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
    // MARK: - Public Properties

    @Published var fiatBalanceValue: String = ""
    @Published var balanceValue: String = ""

    let id: UUID = .init()

    let tokenIconInfo: TokenIconInfo
    let walletName: String
    let tokenName: String

    // MARK: - Private Properties

    private weak var walletModel: WalletModel?

    private var updateSubscription: AnyCancellable?

    // MARK: - Init

    init(walletName: String, walletModel: WalletModel) {
        self.walletName = walletName
        self.walletModel = walletModel

        tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        tokenName = "\(walletModel.tokenItem.currencySymbol) \(walletModel.tokenItem.networkName)"

        bind()
    }

    func bind() {
        updateSubscription = walletModel?
            .walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModelState in
                if walletModelState.isSuccessfullyLoaded {
                    viewModel.fiatBalanceValue = viewModel.walletModel?.fiatBalance ?? ""
                    viewModel.balanceValue = viewModel.walletModel?.balance ?? ""
                }
            }
    }
}
