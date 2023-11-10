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

    @State private var contentOffset: CGPoint = .zero

    private let tokenIconSizeSettings: IconViewSizeSettings = .tokenDetails
    private let headerTopPadding: CGFloat = 14
    private let coorditateSpaceName = "token_details_scroll_space"

    private var toolbarIconOpacity: Double {
        let iconSize = tokenIconSizeSettings.iconSize
        let startAppearingOffset = headerTopPadding + iconSize.height

        let fullAppearanceDistance = iconSize.height / 2
        let fullAppearanceOffset = startAppearingOffset + fullAppearanceDistance

        return clamp(
            (contentOffset.y - startAppearingOffset) / (fullAppearanceOffset - startAppearingOffset),
            min: 0,
            max: 1
        )
    }

    var body: some View {
        RefreshableScrollView(onRefresh: viewModel.onPullToRefresh(completionHandler:)) {
            VStack(spacing: 14) {
                TokenDetailsHeaderView(viewModel: viewModel.tokenDetailsHeaderModel)

                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)

                ForEach(viewModel.tokenNotificationInputs) { input in
                    NotificationView(input: input)
                        .transition(viewModel.shouldShowNotificationsWithAnimation ? .notificationTransition : .identity)
                }

                if viewModel.isMarketPriceAvailable {
                    MarketPriceView(
                        currencySymbol: viewModel.currencySymbol,
                        price: viewModel.rateFormatted,
                        priceChangeState: viewModel.priceChangeState,
                        tapAction: nil
                    )
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
            .padding(.top, headerTopPadding)
            .readContentOffset(
                inCoordinateSpace: .named(coorditateSpaceName),
                bindTo: $contentOffset
            )
        }
        .animation(.default, value: viewModel.tokenNotificationInputs)
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.bottom)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .onDidAppear(viewModel.onDidAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .coordinateSpace(name: coorditateSpaceName)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                TokenIcon(
                    name: "",
                    imageURL: viewModel.iconUrl,
                    customTokenColor: viewModel.customTokenColor,
                    blockchainIconName: nil,
                    isCustom: false,
                    size: IconViewSizeSettings.tokenDetailsToolbar.iconSize
                )
                .opacity(toolbarIconOpacity)
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
