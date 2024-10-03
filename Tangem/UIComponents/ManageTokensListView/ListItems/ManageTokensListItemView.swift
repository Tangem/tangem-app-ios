//
//  ManageTokensListItemView.swift
//  Tangem
//
//  Created by Andrew Son on 21/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensListItemView: View {
    @ObservedObject var viewModel: ManageTokensListItemViewModel

    let isReadOnly: Bool

    private let subtitle: String = Localization.currencySubtitleExpanded
    private let iconWidth: Double = 36

    private var symbolFormatted: String { "  \(viewModel.symbol)" }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                IconView(url: viewModel.imageURL, size: CGSize(width: iconWidth, height: iconWidth), forceKingfisher: true)
                    .padding(.trailing, 12)
                    .saturation((isReadOnly || viewModel.atLeastOneTokenSelected) ? 1.0 : 0.0)

                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        Text(viewModel.name)
                            .font(Fonts.Bold.subheadline)
                            .foregroundColor(Colors.Text.primary1)

                            + Text(symbolFormatted)
                            .font(Fonts.Regular.caption1)
                            .foregroundColor(Colors.Text.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                    HStack {
                        if viewModel.isExpanded {
                            Text(subtitle)
                                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

                            Spacer()
                        }
                    }
                }

                Spacer(minLength: 0)

                chevronView
            }
            .padding(.vertical, 16)
            .zIndex(20)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    viewModel.isExpanded.toggle()
                }
            }

            if viewModel.isExpanded {
                VStack(spacing: 0) {
                    ForEach(viewModel.items) {
                        ManageTokensItemNetworkSelectorView(viewModel: $0, arrowWidth: iconWidth)
                    }
                }
                .transition(.offset(.init(width: 0, height: -25)).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .padding(.horizontal, 16)
    }

    private var chevronView: some View {
        Assets.chevronDown24.image
            .foregroundStyle(Colors.Icon.informative)
            .rotationEffect(viewModel.isExpanded ? Angle(degrees: 180) : .zero)
    }
}

struct ManageTokensListItemView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            let iconBuilder = IconURLBuilder()
            VStack(spacing: 0) {
                StatefulPreviewWrapper(false) {
                    ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                        coinId: "tether",
                        imageURL: iconBuilder.tokenIconURL(id: "tether"),
                        name: "Tether",
                        symbol: "USDT",
                        items: itemsList(count: 11, isSelected: $0)
                    ), isReadOnly: false)
                }

                StatefulPreviewWrapper(false) {
                    ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                        coinId: "binancecoin",
                        imageURL: iconBuilder.tokenIconURL(id: "binancecoin"),
                        name: "Babananas United",
                        symbol: "BABASDT",
                        items: itemsList(count: 15, isSelected: $0)
                    ), isReadOnly: true)
                }

                StatefulPreviewWrapper(false) {
                    ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                        coinId: "binancecoin",
                        imageURL: iconBuilder.tokenIconURL(id: "binancecoin"),
                        name: "Binance USD",
                        symbol: "BUS",
                        items: itemsList(count: 5, isSelected: $0)
                    ), isReadOnly: false)
                }

                StatefulPreviewWrapper(false) {
                    ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                        coinId: "avalanche-2",
                        imageURL: iconBuilder.tokenIconURL(id: "avalanche-2"),
                        name: "USDVVVSALN very-very-very-stupid-and-long-name",
                        symbol: "BUS",
                        items: itemsList(count: 3, isSelected: $0)
                    ), isReadOnly: true)
                }

                StatefulPreviewWrapper(false) {
                    ManageTokensListItemView(viewModel: ManageTokensListItemViewModel(
                        coinId: "ethereum",
                        imageURL: iconBuilder.tokenIconURL(id: "ethereum"),
                        name: "Ethereum",
                        symbol: "ETH",
                        items: itemsList(count: 1, isSelected: $0)
                    ), isReadOnly: false)
                }

                Spacer()
            }
        }
    }

    private static func itemsList(count: Int, isSelected: Binding<Bool>) -> [ManageTokensItemNetworkSelectorViewModel] {
        var viewModels = [ManageTokensItemNetworkSelectorViewModel]()
        for i in 0 ..< count {
            viewModels.append(ManageTokensItemNetworkSelectorViewModel(
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                isReadonly: false,
                isSelected: isSelected,
                position: i == (count - 1) ? .last : i == 0 ? .first : .middle
            ))
        }
        return viewModels
    }
}
