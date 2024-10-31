//
//  ExpressTokensListView.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressTokensListView: View {
    @ObservedObject var viewModel: ExpressTokensListViewModel

    var body: some View {
        ZStack(alignment: .top) {
            Colors.Background.tertiary.ignoresSafeArea(.all)

            mainContent
        }
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: .zero) {
            BottomSheetSearchableHeaderView(
                title: Localization.swappingTokenListTitle,
                searchText: $viewModel.searchText
            )
            .padding(.vertical, 12)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            EmptyView()
        case .isEmpty:
            emptyContent
        case .loaded(let availableTokens, let unavailableTokens):
            GroupedScrollView(alignment: .leading, spacing: 14) {
                if availableTokens.isEmpty, unavailableTokens.isEmpty {
                    emptySearchContent
                } else {
                    section(title: Localization.exchangeTokensAvailableTokensHeader, viewModels: availableTokens)

                    section(title: viewModel.unavailableSectionHeader, viewModels: unavailableTokens)
                }
            }
        }
    }

    private var emptyContent: some View {
        VStack(spacing: .zero) {
            Spacer()

            VStack(spacing: 16) {
                Assets.emptyTokenList.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.inactive)

                Text(Localization.exchangeTokensEmptyTokens)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.horizontal, 50)
            }

            Spacer()
        }
    }

    private var emptySearchContent: some View {
        Text(Localization.expressTokenListEmptySearch)
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .padding(.all, 14)
    }

    private func section(title: String, viewModels: [ExpressTokenItemViewModel]) -> some View {
        GroupedSection(viewModels) {
            ExpressTokenItemView(viewModel: $0)
        } header: {
            DefaultHeaderView(title)
                .padding(.vertical, 12)
        }
    }
}

struct ExpressTokensListView_Preview: PreviewProvider {
    static let viewModel = ExpressModulesFactoryMock().makeExpressTokensListViewModel(
        swapDirection: .fromSource(.mockETH),
        coordinator: ExpressTokensListRoutableMock()
    )

    static var previews: some View {
        ExpressTokensListView(viewModel: viewModel)
    }
}
