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
                ScrollView {
                    VStack(spacing: 14) {
                        MarketsWalletSelectorView(viewModel: viewModel.walletSelectorViewModel)

                        networksContent
                    }
                    .padding(.horizontal, 16)
                }
            }
            .alert(item: $viewModel.alert, content: { $0.alert })
            .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
            .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        }
    }

    private var networksContent: some View {
        VStack(alignment: .leading, spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.marketsSelectWallet)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                tokenInfoView
            }

            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokenItemViewModels) {
                    MarketsTokensNetworkSelectorItemView(viewModel: $0)
                }
            }
        }
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: 14)
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: 12) {
                NetworkIcon(
                    imageName: viewModel.coinIconName,
                    isActive: false,
                    isMainIndicatorVisible: false,
                    size: CGSize(bothDimensions: 36)
                )

                VStack {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.coinIconName)
                            .lineLimit(1)
                            .layoutPriority(-1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.coinSymbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                        Spacer()
                    }

                    Text("Available networks")
                        .style(.footnote, color: Colors.Text.secondary)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

private extension MarketsTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
