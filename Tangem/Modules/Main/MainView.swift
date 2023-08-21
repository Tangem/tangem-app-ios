//
//  MainView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        CardsInfoPagerView(
            data: viewModel.pages,
            selectedIndex: $viewModel.selectedCardIndex,
            headerFactory: { info in
                info.header
                    .contextMenu {
                        Button(action: viewModel.didTapEditWallet, label: editButtonLabel)

                        if #available(iOS 15, *) {
                            Button(role: .destructive, action: viewModel.didTapDeleteWallet, label: deleteButtonLabel)
                        } else {
                            Button(action: viewModel.didTapDeleteWallet, label: deleteButtonLabel)
                        }
                    }
            },
            contentFactory: { info in
                info.body
            },
            onPullToRefresh: viewModel.onPullToRefresh(completionHandler:)
        )
        .pageSwitchThreshold(0.4)
        .contentViewVerticalOffset(64.0)
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .edgesIgnoringSafeArea(.bottom)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Assets.newTangemLogo.image
                    .foregroundColor(Colors.Icon.primary1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 0) {
                    scanCardButton

                    detailsNavigationButton
                }
                .offset(x: 10)
            }
        })
        .alert(item: $viewModel.errorAlert) { $0.alert }
        .actionSheet(isPresented: $viewModel.showingDeleteConfirmation) {
            ActionSheet(
                title: Text(Localization.userWalletListDeletePrompt),
                buttons: [
                    .destructive(Text(Localization.commonDelete), action: viewModel.didConfirmWalletDeletion),
                    .cancel(Text(Localization.commonCancel)),
                ]
            )
        }
        .bottomSheet(
            item: $viewModel.unlockWalletBottomSheetViewModel,
            settings: .init(backgroundColor: Colors.Background.primary)
        ) { model in
            UnlockUserWalletBottomSheetView(viewModel: model)
        }
        .background(
            ScanTroubleshootingView(
                isPresented: $viewModel.showTroubleshootingView,
                tryAgainAction: viewModel.scanCardAction,
                requestSupportAction: viewModel.requestSupport
            )
        )
    }

    var scanCardButton: some View {
        Button(action: viewModel.scanCardAction) {
            Assets.scanWithPhone.image
                .foregroundColor(Colors.Icon.primary1)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
    }

    var detailsNavigationButton: some View {
        Button(action: viewModel.openDetails) {
            NavbarDotsImage()
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
        .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
    }

    @ViewBuilder
    private func editButtonLabel() -> some View {
        HStack {
            Text(Localization.userWalletListRename)
            Image(systemName: "pencil")
        }
    }

    @ViewBuilder
    private func deleteButtonLabel() -> some View {
        HStack {
            Text(Localization.commonDelete)
            Image(systemName: "trash")
        }
    }
}

struct MainView_Preview: PreviewProvider {
    static let viewModel: MainViewModel = {
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        let coordinator = MainCoordinator()
        return .init(coordinator: coordinator, mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: coordinator))
    }()

    static var previews: some View {
        NavigationView {
            MainView(viewModel: viewModel)
        }
    }
}
