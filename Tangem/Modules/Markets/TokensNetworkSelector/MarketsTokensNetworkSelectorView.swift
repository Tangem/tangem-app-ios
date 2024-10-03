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
                    if let walletSelectorViewModel = viewModel.walletSelectorViewModel {
                        MarketsWalletSelectorView(viewModel: walletSelectorViewModel)
                            .onTapGesture {
                                viewModel.selectWalletActionDidTap()
                            }
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
                BlockHeaderTitleView(title: Localization.marketsSelectNetwork)

                tokenInfoView
            }

            networkListView
        }
        .roundedBackground(
            with: Colors.Background.action,
            verticalPadding: .zero,
            horizontalPadding: 14,
            radius: Constants.cornerRadius
        )
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: 12) {
                IconView(url: viewModel.coinIconURL, size: .init(bothDimensions: 36), forceKingfisher: true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.coinName)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.coinSymbol)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                        Spacer()
                    }

                    Text(Localization.marketsAvailableNetworks)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
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

    private var networkListView: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.tokenItemViewModels) {
                MarketsTokensNetworkSelectorItemView(viewModel: $0, arrowWidth: 36)
            }
        }
    }
}

private extension MarketsTokensNetworkSelectorView {
    enum Constants {
        static let cornerRadius = 14.0
    }
}
