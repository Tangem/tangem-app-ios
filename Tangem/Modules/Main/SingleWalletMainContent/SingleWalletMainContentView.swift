//
//  SingleWalletMainContentView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleWalletMainContentView: View {
    @ObservedObject var viewModel: SingleWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(itemsHorizontalOffset: 16, buttonsInfo: viewModel.actionButtons)

            TransactionsListView(
                state: viewModel.transactionHistoryState,
                exploreAction: viewModel.openExplorer,
                reloadButtonAction: viewModel.reloadHistory,
                isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                buyButtonAction: viewModel.canBuyCrypto ? viewModel.openBuy : nil
            )
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 16)
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel: SingleWalletMainContentViewModel = {
        let mainCoordinator = MainCoordinator()
        let userWalletModel = FakeUserWalletModel.xrpNote
        let walletModel = userWalletModel.walletModelsManager.walletModels.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [userWalletModel])
        let cryptoUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        return SingleWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            walletModel: userWalletModel.walletModelsManager.walletModels.first!,
            userTokensManager: userWalletModel.userTokensManager,
            exchangeUtility: cryptoUtility,
            coordinator: mainCoordinator
        )
    }()

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
            .background(Colors.Background.secondary)
    }
}
