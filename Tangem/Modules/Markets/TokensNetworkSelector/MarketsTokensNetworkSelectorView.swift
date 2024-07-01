//
//  MarketsTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by skibinalexander on 21.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokensNetworkSelectorView: View {
    @ObservedObject var viewModel: MarketsTokensNetworkSelectorViewModel

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                groupedContent
            }
            .alert(item: $viewModel.alert, content: { $0.alert })
            .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
            .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        }
    }

    private var groupedContent: some View {
        GroupedScrollView {
            MarketsWalletSelectorView(viewModel: viewModel.walletSelectorViewModel)

            if !viewModel.tokenItemViewModels.isEmpty {
                Spacer(minLength: 14)

                networksContent

                Spacer(minLength: 10)
            }
        }
    }

    private var networksContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.manageTokensNetworkSelectorNativeTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Text(Localization.manageTokensNetworkSelectorNativeSubtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: 10)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokenItemViewModels) {
                    MarketsTokensNetworkSelectorItemView(viewModel: $0)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }
}

private extension MarketsTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
