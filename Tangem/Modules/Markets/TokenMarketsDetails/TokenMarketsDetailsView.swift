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
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.price)
                            .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)

                        HStack {
                            Text(viewModel.priceDate)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                            TokenPriceChangeView(state: viewModel.priceChangeState, showSkeletonWhenLoading: true)
                        }
                    }

                    Spacer(minLength: 8)

                    IconView(url: viewModel.iconURL, size: .init(bothDimensions: 48), forceKingfisher: true)
                }
                Text("Hello, Token Markets Details!")
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text(viewModel.tokenName))

        .background(Colors.Background.tertiary)
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
