//
//  VisaMainContentView.swift
//  Tangem
//
//  Created by Andrew Son on 13/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaWalletMainContentView: View {
    @ObservedObject var viewModel: VisaWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            MainButton(
                title: "Deposit",
                icon: .leading(Assets.arrowDownMini),
                style: .primary,
                size: .default,
                isLoading: false,
                isDisabled: false,
                action: viewModel.openDeposit
            )

            balancesAndLimitsView

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            TransactionsListView(
                state: viewModel.transactionListViewState,
                exploreAction: viewModel.openExplorer,
                exploreTransactionAction: viewModel.exploreTransaction(with:),
                reloadButtonAction: viewModel.reloadTransactionHistory,
                isReloadButtonBusy: viewModel.isTransactoinHistoryReloading,
                fetchMore: viewModel.fetchNextTransactionHistoryPage()
            )
        }
        .padding(.horizontal, 16)
        .bottomSheet(item: $viewModel.balancesAndLimitsViewModel, settings: .init(backgroundColor: Colors.Background.tertiary)) { model in
            VisaBalancesLimitsBottomSheetView(viewModel: model)
        }
    }

    @ViewBuilder
    private var balancesAndLimitsView: some View {
        if let input = viewModel.failedToLoadInfoNotificationInput {
            NotificationView(input: input)
                .transition(.notificationTransition)
        } else {
            Button(action: viewModel.openBalancesAndLimits, label: {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Balances & Limits")
                            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(viewModel.cryptoLimitText)
                                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                            Text(viewModel.numberOfDaysLimitText)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                        .skeletonable(isShown: viewModel.isBalancesAndLimitsBlockLoading, size: .init(width: 160, height: 18), radius: 4)
                    }

                    Spacer()

                    Assets.chevronRight.image
                }
                .defaultRoundedBackground()
            })
        }
    }
}

#Preview {
    let userWalletModel = FakeUserWalletModel.visa
    let coordinator = MainCoordinator()
    let viewModel = VisaWalletMainContentViewModel(
        visaWalletModel: .init(userWalletModel: userWalletModel),
        coordinator: coordinator
    )

    return VisaWalletMainContentView(viewModel: viewModel)
}
