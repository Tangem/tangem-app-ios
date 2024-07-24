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
        VStack {
            header

            list
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsCommonTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .lineLimit(1)

            MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.tokenViewModels.isEmpty, !viewModel.isLoading {
                    noResultTitleView
                }

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
    
    private var noResultTitleView: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                Text(Localization.marketsSearchTokenNoResultTitle)
            }
        }
    }
    
    private var underCapView: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: .zero) {
                Text(Localization.marketsSearchSeeTokensUnder100k)
                    .style(.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: .zero) {
                Button(action: {
                    viewModel.onShowUnderCapAction()
                }, label: {
                    HStack(spacing: .zero) {
                        Text(Localization.marketsSearchShowTokens)
                            .style(Fonts.Regular.footnote.bold(), color: Colors.Text.primary1)
                    }
                })
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
    }
}
