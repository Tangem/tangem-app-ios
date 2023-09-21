//
//  WelcomeTokenListSectionView.swift
//  Tangem
//
//  Created by skibinalexander on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeTokenListSectionView: View {
    @ObservedObject var model: WelcomeTokenListSectionViewModel

    @State private var isExpanded = false

    private let maxNetworkItemsInRow = 10

    private var isItemsOverflows: Bool {
        model.items.count > maxNetworkItemsInRow
    }

    private var itemsCount: Int { isItemsOverflows ? maxNetworkItemsInRow : model.items.count }
    private var symbolFormatted: String { " (\(model.symbol))" }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: model.imageURL, size: CGSize(width: Constants.iconWidth, height: Constants.iconWidth), forceKingfisher: true)
                    .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 6) {
                    Group {
                        Text(model.name)
                            .foregroundColor(.tangemGrayDark6)
                            + Text(symbolFormatted)
                            .foregroundColor(Colors.Text.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .font(Fonts.Bold.body)

                    VStack {
                        if isExpanded {
                            Text(Localization.currencySubtitleExpanded)
                                .font(Fonts.Regular.footnote)
                                .foregroundColor(Colors.Text.tertiary)

                            Spacer()
                        } else {
                            HStack(spacing: 5) {
                                ForEach(0 ..< itemsCount, id: \.id) { index in
                                    if isItemsOverflows, index == (maxNetworkItemsInRow - 1) {
                                        Text("+\(model.items.count - maxNetworkItemsInRow + 1)")
                                            .style(Fonts.Bold.caption2, color: Colors.Icon.informative)
                                            .frame(size: .init(width: 20, height: 20))
                                            .background(Colors.Button.secondary)
                                            .cornerRadiusContinuous(10)
                                    } else {
                                        WelcomeTokenListItemView(model: model.items[index]).icon
                                    }
                                }
                            }
                        }
                    }.frame(height: 20)
                }

                Spacer(minLength: 0)

                chevronView
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(model.items) { WelcomeTokenListItemView(model: $0) }
                }
            }
        }
        .padding(.vertical, 10)
        .animation(nil) // Disable animations on scroll reuse
    }

    private var chevronView: some View {
        Image(systemName: "chevron.down")
            .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
            .foregroundColor(Colors.Icon.informative)
            .padding(.vertical, 4)
    }
}

struct WelcomeTokenListSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatefulPreviewWrapper(false) {
                LegacyCoinView(model: LegacyCoinViewModel(
                    imageURL: nil,
                    name: "Tether",
                    symbol: "USDT",
                    items: itemsList(count: 11, isSelected: $0)
                ))
            }

            StatefulPreviewWrapper(false) {
                LegacyCoinView(model: LegacyCoinViewModel(
                    imageURL: nil,
                    name: "Babananas United",
                    symbol: "BABASDT",
                    items: itemsList(count: 15, isSelected: $0)
                ))
            }

            StatefulPreviewWrapper(false) {
                LegacyCoinView(model: LegacyCoinViewModel(
                    imageURL: nil,
                    name: "Binance USD",
                    symbol: "BUS",
                    items: itemsList(count: 10, isSelected: $0)
                ))
            }

            StatefulPreviewWrapper(false) {
                LegacyCoinView(model: LegacyCoinViewModel(
                    imageURL: nil,
                    name: "Binance USD very-very-long-name",
                    symbol: "BUS",
                    items: itemsList(count: 10, isSelected: $0)
                ))
            }

            Spacer()
        }
        .padding()
    }

    private static func itemsList(count: Int, isSelected: Binding<Bool>) -> [LegacyCoinItemViewModel] {
        Array(repeating: LegacyCoinItemViewModel(
            tokenItem: .blockchain(.ethereum(testnet: false)),
            isReadonly: false,
            isSelected: isSelected,
            position: .first
        ), count: count)
    }
}

extension WelcomeTokenListSectionView {
    private enum Constants {
        static let iconWidth: Double = 46
    }
}
