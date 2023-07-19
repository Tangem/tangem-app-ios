//
//  SingleWalletContentView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct LegacySingleWalletContentView: View {
    @ObservedObject private var viewModel: LegacySingleWalletContentViewModel

    init(viewModel: LegacySingleWalletContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            ForEach(viewModel.pendingTransactionViews) { $0 }
                .padding(.horizontal, 16.0)

            walletView

            LegacyAddressDetailView(
                selectedAddressIndex: $viewModel.selectedAddressIndex,
                walletModel: viewModel.singleWalletModel,
                copyAddress: viewModel.copyAddress,
                showQr: viewModel.openQR,
                showExplorerURL: viewModel.showExplorerURL(url:)
            )
        }
    }

    @ViewBuilder
    private var walletView: some View {
        if let balanceViewModel = viewModel.balanceViewModel {
            switch balanceViewModel.state {
            case .created, .noDerivation:
                EmptyView()

            case .idle, .loading, .failed:
                BalanceView(balanceViewModel: balanceViewModel)
                    .padding(.horizontal, 16.0)

            case .noAccount(let message):
                MessageView(title: Localization.walletErrorNoAccount, subtitle: message, type: .error)
            }
        }
    }
}
