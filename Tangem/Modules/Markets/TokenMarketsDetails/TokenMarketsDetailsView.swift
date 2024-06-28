//
//  TokenMarketsDetailsView.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsView: View {
    @ObservedObject var viewModel: TokenMarketsDetailsViewModel

    var body: some View {
        VStack(spacing: 0) {
            SheetHandleView(backgroundColor: Colors.Background.tertiary)

            NavigationView {
                content
            }
        }
        .background(Colors.Background.tertiary)
    }

    var content: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                header

                MarketsPickerView(
                    marketPriceIntervalType: $viewModel.selectedPriceChangeIntervalType,
                    options: viewModel.priceChangeIntervalOptions,
                    titleFactory: { $0.tokenMarketsDetailsId.capitalizingFirstLetter() }
                )
                .frame(maxWidth: .infinity)

                chart

                Button(action: viewModel.openFullDescription) {
                    Group {
                        Text("\(viewModel.shortDescription) ")
                            + Text(Localization.commonReadMore)
                            .foregroundColor(Colors.Text.accent)
                    }
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)

                contentBlocks
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text(viewModel.tokenName))

        .background(Colors.Background.tertiary)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.price)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.priceDate)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    TokenPriceChangeView(state: viewModel.priceChangeState, showSkeletonWhenLoading: true)
                }
            }

            Spacer(minLength: 8)

            IconView(url: viewModel.iconURL, size: .init(bothDimensions: 48), forceKingfisher: true)
        }
        .padding(.horizontal, 16)
    }

    private var chart: some View {
        // TODO: Insert chart here
        Image(systemName: "chart.xyaxis.line")
            .style(Font.system(size: 80), color: Colors.Icon.accent)
    }

    private var contentBlocks: some View {
        VStack(spacing: 14) {
            MarketsEmptyAddTokenView(didTapAction: viewModel.onAddToPortfolioTapAction)
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    let tokenInfo = MarketsTokenModel(
        id: "bitcoint",
        name: "Bitcoin",
        symbol: "BTC",
        currentPrice: nil,
        priceChangePercentage: [:],
        marketRating: 1,
        marketCap: 100_000_000_000
    )

    return TokenMarketsDetailsView(viewModel: .init(tokenInfo: tokenInfo))
}
