//
//  MainView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import AlertToast

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        CardsInfoPagerView(
            data: viewModel.pages,
            selectedIndex: $viewModel.selectedCardIndex,
            headerFactory: { info in
                info.header
                    .contextMenu {
                        if !info.isLockedWallet {
                            Button(action: viewModel.didTapEditWallet, label: editButtonLabel)

                            if #available(iOS 15, *) {
                                Button(role: .destructive, action: viewModel.didTapDeleteWallet, label: deleteButtonLabel)
                            } else {
                                Button(action: viewModel.didTapDeleteWallet, label: deleteButtonLabel)
                            }
                        }
                    }
            },
            contentFactory: { info in
                info.body
            },
            bottomOverlayFactory: { info, didScrollToBottom in
                info.makeBottomOverlay(didScrollToBottom: didScrollToBottom)
            },
            onPullToRefresh: viewModel.onPullToRefresh(completionHandler:)
        )
        .pageSwitchThreshold(0.4)
        .contentViewVerticalOffset(64.0)
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .onPageChange(viewModel.onPageChange(dueTo:))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Assets.newTangemLogo.image
                    .foregroundColor(Colors.Icon.primary1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 0) {
                    if #unavailable(iOS 15) {
                        // Offset didn't work for iOS 14 if there are no other view in toolbar
                        Spacer()
                            .frame(width: 10)
                    }
                    detailsNavigationButton
                }
            }
        })
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
        .toast(isPresenting: $viewModel.showAddressCopiedToast, alert: {
            AlertToast(type: .complete(Colors.Icon.accent), title: Localization.walletNotificationAddressCopied)
        })
    }

    var detailsNavigationButton: some View {
        Button(action: viewModel.openDetails) {
            NavbarDotsImage()
                .offset(x: 10)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
        .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
    }

    @ViewBuilder
    private func editButtonLabel() -> some View {
        HStack {
            Text(Localization.commonRename)
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
