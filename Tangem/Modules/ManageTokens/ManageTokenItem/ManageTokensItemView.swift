//
//  ManageTokensItemView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensItemView: View {
    @ObservedObject var viewModel: ManageTokensItemViewModel

    private let iconSize = CGSize(bothDimensions: 46)

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(viewModel.name)
                            .lineLimit(1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.symbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }

                    HStack(spacing: 4) {
                        Text(viewModel.priceValue)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                        TokenPriceChangeView(state: viewModel.priceChangeState)
                    }
                }

                Spacer(minLength: 24)

                if let priceHistory = viewModel.priceHistory {
                    LineChartView(
                        color: viewModel.priceHistoryChangeType.textColor,
                        data: priceHistory
                    )
                    .frame(width: 50, height: 37, alignment: .center)
                    .padding(.trailing, 24)
                }

                manageButton(for: viewModel.action, with: viewModel.id)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .animation(nil) // Disable animations on scroll reuse
    }

    @ViewBuilder
    private func manageButton(for action: ManageTokensItemViewModel.Action, with id: String) -> some View {
        ZStack {
            Button {
                viewModel.didTapAction(action, viewModel.coin)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}

struct CurrencyViewNew_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
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
                didTapAction: { _, _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
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
                didTapAction: { _, _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
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
                didTapAction: { _, _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
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
                didTapAction: { _, _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
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
                didTapAction: { _, _ in }
            ))

            ManageTokensItemView(viewModel: ManageTokensItemViewModel(
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
                didTapAction: { _, _ in }
            ))

            Spacer()
        }
    }
}
