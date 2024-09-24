//
//  OnboardingAddTokensView.swift
//  Tangem
//
//  Created by Andrew Son on 27/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingAddTokensView: View {
    @ObservedObject var viewModel: OnboardingAddTokensViewModel

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

                MainButton(settings: viewModel.buttonSettings)
                    .padding(.bottom, 6)
                    .padding(.horizontal, 16)
                    .background(
                        ListFooterOverlayShadowView()
                            .padding(.top, -30)
                    )
            }
        }
        .scrollDismissesKeyboardCompat(.interactively)
        .keyboardType(.alphabet)
    }
}

#Preview {
    let fakeModel = FakeUserWalletModel.wallet3Cards
    let fakeAPIService = FakeTangemApiService()
    InjectedValues[\.tangemApiService] = fakeAPIService
    let adapter = ManageTokensAdapter(
        settings: .init(
            longHashesSupported: fakeModel.config.hasFeature(.longHashes),
            existingCurves: fakeModel.config.existingCurves,
            supportedBlockchains: fakeModel.config.supportedBlockchains,
            userTokensManager: fakeModel.userTokensManager,
            analyticsSourceRawValue: "preview"
        )
    )

    return OnboardingAddTokensView(viewModel: OnboardingAddTokensViewModel(adapter: adapter, delegate: nil))
}
