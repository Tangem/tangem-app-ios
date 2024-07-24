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

    var body: some View {
        ZStack {
            VStack {
                header

                list
            }

            emptyList
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isSerching {
                HStack {
                    Text(Localization.marketsSearchResultTitle)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)
                        .lineLimit(1)

                    Spacer()
                }
            } else {
                Text(Localization.marketsCommonTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .lineLimit(1)

                MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokenViewModels) {
                    MarketsItemView(viewModel: $0)
                }

                if viewModel.isShowUnderCapButton {
                    underCapView
                }

                // Need for display list skeleton view
                if viewModel.isLoading {
                    ForEach(0 ..< 20) { _ in
                        MarketsSkeletonItemView()
                    }
                }

                if viewModel.hasNextPage, viewModel.viewDidAppear {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                        .onAppear(perform: viewModel.fetchMore)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyList: some View {
        if let state = viewModel.emptyTokensState {
            Group {
                switch state {
                case .noResults:
                    // Display empty state if needed
                    noResultTitleView
                case .error:
                    // Display error state if needed
                    errorListView
                }
            }
        }
    }

    private var noResultTitleView: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                Text(Localization.marketsSearchTokenNoResultTitle)
                    .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            }
        }
    }

    private var underCapView: some View {
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

    private var errorListView: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack(spacing: .zero) {
                Text(Localization.marketsLoadingErrorTitle)
                    .style(.caption, color: Colors.Text.tertiary)
            }

            HStack(spacing: .zero) {
                Button(action: {
                    viewModel.onTryLoadList()
                }, label: {
                    HStack(spacing: .zero) {
                        Text(Localization.tryToLoadDataAgainButtonTitle)
                            .style(Fonts.Regular.footnote.bold(), color: Colors.Text.primary1)
                    }
                })
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
    }
}

extension MarketsView {
    enum EmptyTokensState: Int, Identifiable, Hashable {
        var id: Int { rawValue }

        case noResults
        case error
    }
}
