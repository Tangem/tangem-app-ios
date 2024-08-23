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
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 14) {
                    if viewModel.isShowWalletSelector {
                        MarketsWalletSelectorView(viewModel: viewModel.walletSelectorViewModel)
                    }

                    contentView

                    if !viewModel.pendingAdd.isEmpty {
                        MarketsGeneratedAddressView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 72)
            }

            overlayButtonView
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.manageTokensNetworkSelectorTitle), displayMode: .inline)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.marketsSelectNetwork)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                tokenInfoView
            }

            VStack(spacing: .zero) {
                ForEach(viewModel.tokenItemViewModels) {
                    MarketsTokensNetworkSelectorItemView(viewModel: $0)
                }
            }
            .padding(.leading, 8)
        }
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: Constants.cornerRadius)
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: 12) {
                IconView(url: viewModel.coinIconURL, size: .init(bothDimensions: 36), forceKingfisher: true)

                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.coinName)
                            .lineLimit(1)
                            .layoutPriority(-1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.coinSymbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                        Spacer()
                    }

                    Text(Localization.marketsAvailableNetworks)
                        .style(.footnote, color: Colors.Text.secondary)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var overlayButtonView: some View {
        VStack {
            Spacer()

            MainButton(
                title: Localization.commonContinue,
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isSaving,
                isDisabled: viewModel.isSaveDisabled,
                action: viewModel.saveChangesOnTapAction
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(LinearGradient(
                colors: [Colors.Background.primary, Colors.Background.primary, Colors.Background.primary.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .edgesIgnoringSafeArea(.bottom))
        }
    }
}

private extension MarketsTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
