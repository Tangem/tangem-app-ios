//
//  ManageTokensView.swift
//  Tangem
//
//  Created by Andrew Son on 29/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    @State private var contentOffset: CGPoint = .zero

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CustomSearchBar(searchText: $viewModel.searchText, placeholder: Localization.commonSearch)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if contentOffset.y > 0 {
                    Divider()
                }

                ManageTokensListView(viewModel: viewModel.manageTokensListViewModel)
                    .addContentOffsetObserver($contentOffset)
            }

            VStack {
                Spacer()

                MainButton(
                    title: Localization.commonSave,
                    icon: .trailing(Assets.tangemIcon),
                    isLoading: viewModel.isSavingChanges,
                    action: viewModel.saveChanges
                )
                .padding(.bottom, 10)
                .padding(.horizontal, 16)
                .background(
                    ListFooterOverlayShadowView()
                        .padding(.top, -30)
                )
                .hidden(viewModel.isPendingListEmpty)
                .animation(.default, value: viewModel.isPendingListEmpty)
            }
        }
        .background(Colors.Background.primary.ignoresSafeArea())
        .navigationTitle(Text(Localization.addTokensTitle))
        .scrollDismissesKeyboardCompat(.interactively)
        .keyboardType(.alphabet)
        .bindAlert($viewModel.alert)
    }
}

#Preview {
    let fakeModel = FakeUserWalletModel.wallet3Cards
    let fakeAPIService = FakeTangemApiService()
    InjectedValues[\.tangemApiService] = fakeAPIService
    let adapter = ManageTokensAdapter(settings: .init(
        longHashesSupported: fakeModel.config.hasFeature(.longHashes),
        existingCurves: fakeModel.config.existingCurves,
        supportedBlockchains: fakeModel.config.supportedBlockchains,
        userTokensManager: fakeModel.userTokensManager
    ))

    return NavigationView {
        ManageTokensView(viewModel: .init(adapter: adapter))
    }
}
