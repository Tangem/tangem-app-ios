//
//  MarketsItemView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsItemView: View {
    @ObservedObject var viewModel: MarketsItemViewModel

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)
                    .skeletonable(isShown: viewModel.isLoading, radius: iconSize.height / 2)

                tokenInfo
            }

            Spacer(minLength: 24)

            priceHistoryView

            manageButton(for: viewModel.action, with: viewModel.id)
                .skeletonable(isShown: viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .animation(nil) // Disable animations on scroll reuse
    }

    @ViewBuilder
    private func manageButton(for action: MarketsItemViewModel.Action, with id: String) -> some View {
        ZStack {
            Button {
                viewModel.didTapAction(action, viewModel.coinModel)
            } label: {
                switch action {
                case .add:
                    AddButtonView()
                case .edit:
                    EditButtonView()
                case .info:
                    Assets.infoIconMini.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                }
            }

            AddButtonView()
                .hidden()

            EditButtonView()
                .hidden()
        }
    }

    private var tokenInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstBaselineCustom, spacing: 4) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .skeletonable(isShown: viewModel.isLoading, radius: 3)

                Text(viewModel.symbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            HStack(spacing: 6) {
                Text(viewModel.priceValue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .skeletonable(isShown: viewModel.isLoading, radius: 3)

                if !viewModel.isLoading {
                    TokenPriceChangeView(state: viewModel.priceChangeState)
                }
            }
        }
    }

    private var priceHistoryView: some View {
        VStack {
            if let priceHistory = viewModel.priceHistory {
                LineChartView(
                    color: viewModel.priceHistoryChangeType.textColor,
                    data: priceHistory
                )
            }
        }
        .frame(width: 50, height: 37, alignment: .center)
        .padding(.trailing, 24)
    }
}

private struct AddButtonView: View {
    var body: some View {
        TextButtonView(text: Localization.manageTokensAdd, foreground: Colors.Text.primary2, background: Colors.Button.primary)
    }
}

private struct EditButtonView: View {
    var body: some View {
        TextButtonView(text: Localization.manageTokensEdit, foreground: Colors.Text.primary1, background: Colors.Button.secondary)
    }
}

private struct TextButtonView: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .style(Fonts.Bold.caption1, color: foreground)
            .frame(size: .init(width: 24, height: 16))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(background)
            )
    }
}

struct MarketsItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MarketsItemView(viewModel: MarketsItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Bitcoin",
                    symbol: "BTC",
                    items: []
                ),
                priceValue: "$23,034.83",
                priceChangeState: .loaded(signType: .positive, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13],
                action: .add,
                state: .loaded,
                didTapAction: { _, _ in }
            ))

            MarketsItemView(viewModel: MarketsItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Ethereum",
                    symbol: "ETH",
                    items: []
                ),
                priceValue: "$1,340.33",
                priceChangeState: .loaded(signType: .negative, text: "10.5%"),
                priceHistory: [1, 7, 3, 5, 13].reversed(),
                action: .add,
                state: .loaded,
                didTapAction: { _, _ in }
            ))

            MarketsItemView(viewModel: MarketsItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Solana",
                    symbol: "SOL",
                    items: []
                ),
                priceValue: "$33.00",
                priceChangeState: .loaded(signType: .positive, text: "1.3%"),
                priceHistory: [1, 7, 3, 5, 13],
                action: .add,
                state: .loaded,
                didTapAction: { _, _ in }
            ))

            MarketsItemView(viewModel: MarketsItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Polygon",
                    symbol: "MATIC",
                    items: []
                ),
                priceValue: "$34.83",
                priceChangeState: .loaded(signType: .positive, text: "0.0%"),
                priceHistory: [4, 7, 3, 5, 4],
                action: .edit,
                state: .loaded,
                didTapAction: { _, _ in }
            ))

            MarketsItemView(viewModel: MarketsItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Very long token name is very long",
                    symbol: "BUS",
                    items: []
                ),
                priceValue: "$23,341,324,034.83",
                priceChangeState: .loaded(signType: .positive, text: "1,444,340,340.0%"),
                priceHistory: [1, 7, 3, 5, 13],
                action: .info,
                state: .loaded,
                didTapAction: { _, _ in }
            ))

            MarketsItemView(viewModel: MarketsItemViewModel(
                coinModel: CoinModel(
                    id: "",
                    name: "Custom Token",
                    symbol: "CT",
                    items: []
                ),
                priceValue: "$100.83",
                priceChangeState: .loaded(signType: .positive, text: "1.0%"),
                priceHistory: nil,
                action: .add,
                state: .loaded,
                didTapAction: { _, _ in }
            ))

            Spacer()
        }
    }
}
