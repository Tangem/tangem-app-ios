//
//  MarketsView.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct MarketsView: View {
    @ObservedObject var viewModel: MarketsViewModel

    private let scrollTopAnchorID = "markets_scroll_view_top_anchor_id"

    var body: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.isSearching {
                searchResultView
            } else {
                defaultMarketsView
            }
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .background(Colors.Background.primary)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .background(Colors.Background.primary)
    }

    @ViewBuilder
    private var defaultMarketsView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localization.marketsCommonTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            list
        }

        if case .error = viewModel.tokenListLoadingState {
            errorStateView
        }
    }

    @ViewBuilder
    private var list: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                Color.clear.frame(height: 0)
                    .id(scrollTopAnchorID)

                LazyVStack(spacing: 0) {
                    ForEach(viewModel.tokenViewModels) {
                        MarketsItemView(viewModel: $0)
                    }

                    // Need for display list skeleton view
                    if case .loading = viewModel.tokenListLoadingState {
                        loadingSkeletons
                    }

                    if viewModel.shouldDisplayShowTokensUnderCapView {
                        showTokensUnderCapView
                    }
                }
                .onReceive(viewModel.resetScrollPositionPublisher) { _ in
                    proxy.scrollTo(scrollTopAnchorID)
                }
            }
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 20) { _ in
            MarketsSkeletonItemView()
        }
    }

    @ViewBuilder
    private var searchResultView: some View {
        switch viewModel.tokenListLoadingState {
        case .noResults:
            noResultsStateView
        case .error:
            errorStateView
        case .loading, .allDataLoaded, .idle:
            VStack(spacing: 12) {
                Text(Localization.marketsSearchResultTitle)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                list
            }
        }
    }

    private var showTokensUnderCapView: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: .zero) {
                Text(Localization.marketsSearchSeeTokensUnder100k)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: .zero) {
                Button(action: {
                    viewModel.onShowUnderCapAction()
                }, label: {
                    HStack(spacing: .zero) {
                        Text(Localization.marketsSearchShowTokens)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    }
                })
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
        .padding(.vertical, 12)
    }

    private var noResultsStateView: some View {
        Text(Localization.marketsSearchTokenNoResultTitle)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
    }

    private var errorStateView: some View {
        MarketsUnableToLoadDataView(
            isButtonBusy: viewModel.tokenListLoadingState == .loading,
            retryButtonAction: viewModel.onTryLoadList
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

extension MarketsView {
    enum ListLoadingState: String, Identifiable, Hashable {
        case noResults
        case error
        case loading
        case allDataLoaded
        case idle

        var id: String { rawValue }
    }
}
