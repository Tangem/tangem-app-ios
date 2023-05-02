//
//  UserWalletListView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListView: View {
    @ObservedObject private var viewModel: UserWalletListViewModel

    private let listHorizontalPadding: Double = 16

    init(viewModel: UserWalletListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text(Localization.userWalletListTitle)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                userWalletsView()

                Group {
                    if viewModel.isLocked {
                        MainButton(
                            title: viewModel.unlockAllButtonTitle,
                            style: .secondary,
                            isDisabled: viewModel.isScanningCard,
                            action: viewModel.unlockAllWallets
                        )
                    }

                    MainButton(
                        title: Localization.userWalletListAddButton,
                        icon: .trailing(Assets.tangemIcon),
                        isLoading: viewModel.isScanningCard,
                        action: viewModel.addUserWallet
                    )
                }
                .padding(.horizontal, listHorizontalPadding)
            }
        }
        .padding(.vertical, 16)
        .alert(item: $viewModel.error) {
            $0.alert
        }
        .actionSheet(isPresented: $viewModel.showingDeleteConfirmation) {
            ActionSheet(
                title: Text(Localization.userWalletListDeletePrompt),
                buttons: [
                    .destructive(Text(Localization.commonDelete), action: viewModel.didConfirmWalletDeletion),
                    .cancel(Text(Localization.commonCancel), action: viewModel.didCancelWalletDeletion),
                ]
            )
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .background(
            ScanTroubleshootingView(
                isPresented: $viewModel.showTroubleshootingView,
                tryAgainAction: viewModel.tryAgain,
                requestSupportAction: viewModel.requestSupport
            )
        )
        .onAppear(perform: viewModel.onAppear)
    }
}

extension UserWalletListView {
    // MARK: - List

    @ViewBuilder
    private func userWalletsView() -> some View {
        if #available(iOS 16, *) {
            userWalletsList()
                .scrollContentBackground(.hidden)
        } else if #available(iOS 15, *) {
            // List is available from 14 onwards but we've decided not to use it due to issues with Separators
            userWalletsList()
        } else {
            userWalletsScrollView()
        }
    }

    @ViewBuilder
    private func userWalletsList() -> some View {
        List {
            sections()
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func userWalletsScrollView() -> some View {
        // Using ScrollView because we can't hide default separators in List on prior OS versions.
        // And since we don't use List we can't use onDelete for the swipe action either.
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                sections()
            }
            .background(Colors.Background.primary)
            .cornerRadius(14)
            .padding(.horizontal, listHorizontalPadding)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func sections() -> some View {
        section(Localization.userWalletListMultiHeader, for: viewModel.multiCurrencyModels)
        section(Localization.userWalletListSingleHeader, for: viewModel.singleCurrencyModels)
    }

    @ViewBuilder
    private func section(_ headerName: String, for viewModels: [UserWalletListCellViewModel]) -> some View {
        if !viewModels.isEmpty {
            sectionHeader(name: headerName)

            ForEach(viewModels, id: \.userWalletId) { cellViewModel in
                UserWalletListCellView(viewModel: cellViewModel)

                if cellViewModel.userWalletId != viewModels.last?.userWalletId {
                    UserWalletListSeparatorView()
                }
            }
        }
    }

    // MARK: - Headers

    @ViewBuilder
    private func sectionHeader(name: String) -> some View {
        if #available(iOS 15, *) {
            sectionHeaderInternal(name: name)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        } else {
            sectionHeaderInternal(name: name)
        }
    }

    @ViewBuilder
    private func sectionHeaderInternal(name: String) -> some View {
        UserWalletListHeaderView(name: name)
    }
}
