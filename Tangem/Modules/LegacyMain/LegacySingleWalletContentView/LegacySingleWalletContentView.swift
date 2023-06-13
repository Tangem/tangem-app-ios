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

            if viewModel.canShowAddress {
                walletView

                if let walletModel = viewModel.singleWalletModel {
                    LegacyAddressDetailView(
                        selectedAddressIndex: $viewModel.selectedAddressIndex,
                        walletModel: walletModel,
                        copyAddress: viewModel.copyAddress,
                        showQr: viewModel.openQR,
                        showExplorerURL: viewModel.showExplorerURL(url:)
                    )
                }

            } else {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                            .padding([.horizontal, .top], 16)
                            .padding(.bottom, viewModel.totalBalanceButtons.isEmpty ? 16 : 0)

                        if !viewModel.totalBalanceButtons.isEmpty {
                            HStack {
                                ForEach(viewModel.totalBalanceButtons) { buttonInfo in
                                    Button(action: buttonInfo.action) {
                                        HStack {
                                            buttonInfo.icon.image
                                                .renderingMode(.template)
                                                .foregroundColor(Colors.Icon.primary1)
                                                .frame(width: 16, height: 16)

                                            Text(buttonInfo.title)
                                                .style(
                                                    Fonts.Bold.callout,
                                                    color: Colors.Text.primary1
                                                )
                                        }
                                        .padding(.vertical, 9)
                                        .frame(maxWidth: .infinity)
                                        .background(Colors.Button.secondary)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 19)
                        }
                    }
                    .background(Colors.Background.primary)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)

                    if viewModel.canShowTransactionHistory {
                        TransactionsListView(state: viewModel.transactionHistoryState)
                            .background(Colors.Background.primary)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var walletView: some View {
        if let singleWalletModel = viewModel.singleWalletModel {
            switch singleWalletModel.state {
            case .created, .noDerivation:
                EmptyView()

            case .idle, .loading, .failed:
                BalanceView(balanceViewModel: singleWalletModel.legacySingleCurrencyViewModel())
                    .padding(.horizontal, 16.0)

            case .noAccount(let message):
                MessageView(title: Localization.walletErrorNoAccount, subtitle: message, type: .error)
            }
        }
    }
}
