//
//  TokenDetailsView.swift
//  Tangem
//
//  Created by Andrew Son on 09/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsView: View {
    @ObservedObject var viewModel: TokenDetailsViewModel

    @StateObject private var scrollState = TokenDetailsScrollState(
        tokenIconSizeSettings: Constants.tokenIconSizeSettings,
        headerTopPadding: Constants.headerTopPadding
    )

    private let coorditateSpaceName = UUID()

    var body: some View {
        RefreshableScrollView(onRefresh: viewModel.onPullToRefresh(completionHandler:)) {
            VStack(spacing: 14) {
                TokenDetailsHeaderView(viewModel: viewModel.tokenDetailsHeaderModel)

                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)

                ForEach(viewModel.tokenNotificationInputs) { input in
                    NotificationView(input: input)
                        .transition(.notificationTransition)
                }

                if viewModel.isMarketPriceAvailable {
                    MarketPriceView(
                        currencySymbol: viewModel.currencySymbol,
                        price: viewModel.rateFormatted,
                        priceChangeState: viewModel.priceChangeState,
                        tapAction: nil
                    )
                }

                ForEach(viewModel.pendingExpressTransactions) { transactionInfo in
                    PendingExpressTransactionView(info: transactionInfo)
                        .transition(.notificationTransition)
                }

                PendingTransactionsListView(
                    items: viewModel.pendingTransactionViews,
                    exploreTransactionAction: viewModel.openTransactionExplorer
                )

                TransactionsListView(
                    state: viewModel.transactionHistoryState,
                    exploreAction: viewModel.openExplorer,
                    exploreTransactionAction: viewModel.openTransactionExplorer,
                    reloadButtonAction: viewModel.reloadHistory,
                    isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                    fetchMore: viewModel.fetchMoreHistory()
                )
                .padding(.bottom, 40)
            }
            .padding(.top, Constants.headerTopPadding)
            .readContentOffset(
                inCoordinateSpace: .named(coorditateSpaceName),
                bindTo: scrollState.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )
        }
        .animation(.default, value: viewModel.tokenNotificationInputs)
        .animation(.default, value: viewModel.pendingExpressTransactions)
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.bottom)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .coordinateSpace(name: coorditateSpaceName)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                TokenIcon(
                    tokenIconInfo: .init(
                        name: "",
                        blockchainIconName: nil,
                        imageURL: viewModel.iconUrl,
                        isCustom: false,
                        customTokenColor: viewModel.customTokenColor
                    ),
                    size: IconViewSizeSettings.tokenDetailsToolbar.iconSize
                )
                .opacity(scrollState.toolbarIconOpacity)
            }

            ToolbarItem(placement: .navigationBarTrailing) { navbarTrailingButton }
        })
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var navbarTrailingButton: some View {
        if viewModel.canHideToken {
            Menu {
                if #available(iOS 15.0, *) {
                    Button(Localization.tokenDetailsHideToken, role: .destructive, action: viewModel.hideTokenButtonAction)
                } else {
                    Button(Localization.tokenDetailsHideToken, action: viewModel.hideTokenButtonAction)
                }
            } label: {
                NavbarDotsImage()
            }
        }
    }
}

// MARK: - Constants

private extension TokenDetailsView {
    enum Constants {
        static let tokenIconSizeSettings: IconViewSizeSettings = .tokenDetails
        static let headerTopPadding: CGFloat = 14.0
    }
}
