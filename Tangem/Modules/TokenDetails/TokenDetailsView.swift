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

    private let tokenIconSizeSettings: TokenIconView.SizeSettings = .tokenDetails
    private let headerTopPadding: CGFloat = 14
    private let coorditateSpaceName = "token_details_scroll_space"

    private var tokenIconViewModel: TokenIconViewModel {
        TokenIconViewModel(id: viewModel.tokenItem.id, name: viewModel.tokenItem.name, style: .blockchain)
    }

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
        RefreshableScrollView(onRefresh: viewModel.onRefresh) {
            VStack(spacing: 14) {
                TokenDetailsHeaderView(viewModel: viewModel.tokenDetailsHeaderModel)

                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)

                TransactionsListView(
                    state: viewModel.transactionHistoryState,
                    exploreAction: viewModel.openExplorer,
                    reloadButtonAction: viewModel.reloadHistory,
                    isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                    buyButtonAction: viewModel.canBuyCrypto ? viewModel.openBuy : nil,
                    shouldAddFetchMoreBlock: viewModel.canFetchMoreTransactionHistory,
                    fetchMoreBlock: viewModel.loadHistory
                )
                .padding(.bottom, 40)
            }
            .padding(.top, headerTopPadding)
            .readContentOffset(
                inCoordinateSpace: .named(coorditateSpaceName),
                bindTo: $contentOffset
            )
        }
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.bottom)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .coordinateSpace(name: coorditateSpaceName)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                TokenIconView(viewModel: tokenIconViewModel, sizeSettings: .tokenDetailsToolbar)
                    .opacity(toolbarIconOpacity)
            }

            ToolbarItem(placement: .navigationBarTrailing) { navbarTrailingButton }
        })
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var navbarTrailingButton: some View {
        Menu {
            if #available(iOS 15.0, *) {
                Button(Localization.tokenDetailsHideToken, role: .destructive, action: viewModel.hideTokenButtonAction)
            } else {
                Button(Localization.tokenDetailsHideToken, action: viewModel.hideTokenButtonAction)
            }
        } label: {
            NavbarDotsImage()
                .offset(x: 11)
        }
    }
}
