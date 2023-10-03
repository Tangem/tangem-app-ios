//
//  MultiWalletContentView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct LegacyMultiWalletContentView: View {
    @ObservedObject private var viewModel: LegacyMultiWalletContentViewModel

    init(viewModel: LegacyMultiWalletContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if !viewModel.tokenListIsEmpty {
                TotalSumBalanceView(viewModel: viewModel.totalSumBalanceViewModel)
                    .padding(16)
                    .background(Colors.Background.primary)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
            }

            tokenList

            MainButton(
                title: Localization.mainManageTokens,
                action: viewModel.openTokensList
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder var tokenList: some View {
        if !viewModel.tokenListIsEmpty {
            VStack(alignment: .center, spacing: 0) {
                Text(Localization.mainTokens)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .top], 16)

                content
            }
            .frame(maxWidth: .infinity)
            .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder var content: some View {
        switch viewModel.contentState {
        case .loading:
            ActivityIndicatorView(color: .gray)
                .padding()

        case .loaded(let viewModels):
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModels) { item in
                    VStack(spacing: 0) {
                        Button(action: { viewModel.tokenItemDidTap(item) }) {
                            LegacyTokenItemView(item: item)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 15)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(TangemTokenButtonStyle())
                        .disabled(item.state == .noDerivation)

                        if viewModels.last != item {
                            Separator(height: .exact(1), color: .tangemBgGray2)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
        case .failedToLoad:
            // State related to new design. So it won't occur in legacy version. Will be removed after integration of new design
            EmptyView()
        }
    }
}
