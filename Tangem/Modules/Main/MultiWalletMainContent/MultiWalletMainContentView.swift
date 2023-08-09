//
//  MultiWalletMainContentView.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultiWalletMainContentView: View {
    @ObservedObject var viewModel: MultiWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            if viewModel.pendingDerivationsCount > 0 {
                MissingAddressesWarningView(
                    missingAddressesCount: viewModel.pendingDerivationsCount,
                    isLoading: viewModel.isScannerBusy,
                    action: viewModel.deriveEntriesWithoutDerivation
                )
                .transition(AnyTransition.scale.combined(with: .opacity))
            }

            tokensContent
        }
        .animation(.default, value: viewModel.pendingDerivationsCount)
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    private var tokensContent: some View {
        Group {
            if viewModel.isLoadingTokenList {
                TokenListLoadingPlaceholderView()
            } else {
                if viewModel.sections.isEmpty {
                    emptyList
                } else {
                    tokensList
                }
            }
        }
        .cornerRadiusContinuous(14)
    }

    private var emptyList: some View {
        // TODO: This will be updated later after updates from the design team
        Text("To begin tracking your crypto assets and transactions, add tokens.")
            .multilineTextAlignment(.center)
            .style(
                Fonts.Regular.caption1,
                color: Colors.Text.tertiary
            )
            .padding(.top, 150)
            .padding(.horizontal, 48)
    }

    private var tokensList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.sections) { section in
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let title = section.title {
                        Text(title)
                            .style(
                                Fonts.Bold.footnote,
                                color: Colors.Text.tertiary
                            )
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                    }

                    ForEach(section.tokenItemModels) { item in
                        TokenItemView(viewModel: item)
                    }
                }
            }
        }
        .background(Colors.Background.primary)
    }
}

struct MultiWalletContentView_Preview: PreviewProvider {
    static var sectionProvider: TokenListInfoProvider = EmptyTokenListInfoProvider()
    static let viewModel: MultiWalletMainContentViewModel = {
        let repo = FakeUserWalletRepository()
        let mainCoordinator = MainCoordinator()
        let userWalletModel = repo.models.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        sectionProvider = GroupedTokenListInfoProvider(
            userTokenListManager: userWalletModel.userTokenListManager,
            walletModelsManager: userWalletModel.walletModelsManager
        )
        return MultiWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            coordinator: mainCoordinator,
            sectionsProvider: sectionProvider
        )
    }()

    static var previews: some View {
        ScrollView {
            MultiWalletMainContentView(viewModel: viewModel)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
