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

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.tokenDetails(
        tokenIconSizeSettings: Constants.tokenIconSizeSettings,
        headerTopPadding: Constants.headerTopPadding
    )

    private let coordinateSpaceName = UUID()

    var body: some View {
        RefreshableScrollView(onRefresh: viewModel.onPullToRefresh(completionHandler:)) {
            VStack(spacing: 14) {
                TokenDetailsHeaderView(viewModel: viewModel.tokenDetailsHeaderModel)

                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)

                ForEach(viewModel.bannerNotificationInputs) { input in
                    NotificationView(input: input)
                        .transition(.notificationTransition)
                }

                ForEach(viewModel.tokenNotificationInputs) { input in
                    NotificationView(input: input)
                        .transition(.notificationTransition)
                }

                if viewModel.isMarketsDetailsAvailable {
                    MarketPriceView(
                        currencySymbol: viewModel.currencySymbol,
                        price: viewModel.rateFormatted,
                        priceChangeState: viewModel.priceChangeState,
                        miniChartData: viewModel.miniChartData,
                        tapAction: viewModel.openMarketsTokenDetails
                    )
                }

                if let activeStakingViewData = viewModel.activeStakingViewData {
                    ActiveStakingView(data: activeStakingViewData)
                        .padding(14)
                        .background(Colors.Background.primary)
                        .cornerRadiusContinuous(14)
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
                    reloadButtonAction: viewModel.onButtonReloadHistory,
                    isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                    fetchMore: viewModel.fetchMoreHistory()
                )
                .padding(.bottom, 40)
            }
            .padding(.top, Constants.headerTopPadding)
            .readContentOffset(
                inCoordinateSpace: .named(coordinateSpaceName),
                bindTo: scrollOffsetHandler.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )
        }
        .animation(.default, value: viewModel.bannerNotificationInputs)
        .animation(.default, value: viewModel.tokenNotificationInputs)
        .animation(.default, value: viewModel.pendingExpressTransactions)
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.bottom)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: scrollOffsetHandler.onViewAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .coordinateSpace(name: coordinateSpaceName)
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
                .opacity(scrollOffsetHandler.state)
            }

            ToolbarItem(placement: .navigationBarTrailing) { navbarTrailingButton }
        })
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var navbarTrailingButton: some View {
        if viewModel.hasDotsMenu {
            Menu {
                if viewModel.canGenerateXPUB {
                    Button(Localization.tokenDetailsGenerateXpub, action: viewModel.generateXPUBButtonAction)
                }

                if viewModel.canHideToken {
                    Button(Localization.tokenDetailsHideToken, role: .destructive, action: viewModel.hideTokenButtonAction)
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

#Preview {
    let userWalletModel = FakeUserWalletModel.wallet3Cards
    let walletModel = userWalletModel.walletModelsManager.walletModels.first ?? .mockETH
    let exchangeUtility = ExchangeCryptoUtility(
        blockchain: walletModel.blockchainNetwork.blockchain,
        address: walletModel.defaultAddress,
        amountType: walletModel.tokenItem.amountType
    )
    let notifManager = SingleTokenNotificationManager(
        walletModel: walletModel,
        walletModelsManager: userWalletModel.walletModelsManager,
        contextDataProvider: nil
    )
    let pendingExpressTxsManager = CommonPendingExpressTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        walletModel: walletModel,
        expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
    )
    let pendingOnrampTxsManager = CommonPendingOnrampTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        walletModel: walletModel
    )
    let pendingTxsManager = CompoundPendingTransactionsManager(
        first: pendingExpressTxsManager,
        second: pendingOnrampTxsManager
    )
    let coordinator = TokenDetailsCoordinator()

    let bannerNotificationManager = BannerNotificationManager(userWalletId: UserWalletId(value: Data()), placement: .tokenDetails(walletModel.tokenItem), contextDataProvider: nil)

    return TokenDetailsView(viewModel: .init(
        userWalletModel: userWalletModel,
        walletModel: walletModel,
        exchangeUtility: exchangeUtility,
        notificationManager: notifManager,
        bannerNotificationManager: bannerNotificationManager,
        pendingExpressTransactionsManager: pendingTxsManager,
        xpubGenerator: nil,
        coordinator: coordinator,
        tokenRouter: SingleTokenRouter(userWalletModel: userWalletModel, coordinator: coordinator)
    ))
}
