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

            if !viewModel.nativeSelectorItems.isEmpty {
                Spacer(minLength: 14)

                nativeNetworksContent

                Spacer(minLength: 10)
            }

            if !viewModel.nonNativeSelectorItems.isEmpty {
                Spacer(minLength: 14)

                noneNativeNetworksContent
            }
        }
    }

    private var nativeNetworksContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.manageTokensNetworkSelectorNativeTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Text(Localization.manageTokensNetworkSelectorNativeSubtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: 10)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.nativeSelectorItems) {
                    MarketsTokensNetworkSelectorItemView(viewModel: $0)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private var noneNativeNetworksContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: viewModel.displayNonNativeNetworkAlert) {
                HStack(spacing: 4) {
                    Text(Localization.manageTokensNetworkSelectorNonNativeTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Assets.infoIconMini.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(size: .init(bothDimensions: 20))
                        .foregroundColor(Colors.Icon.inactive)

                    Spacer()
                }
            }

            Text(Localization.manageTokensNetworkSelectorNonNativeSubtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: 10)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.nonNativeSelectorItems) {
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
