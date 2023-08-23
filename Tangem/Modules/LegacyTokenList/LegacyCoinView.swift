//
//  LegacyCoinView.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

struct LegacyCoinView: View {
    @ObservedObject var model: LegacyCoinViewModel
    var subtitle: String = Localization.currencySubtitleExpanded

    let iconWidth: Double = 46

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
                IconView(url: model.imageURL, size: CGSize(width: iconWidth, height: iconWidth), forceKingfisher: true)
                    .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 6) {
                    Group {
                        Text(model.name)
                            .foregroundColor(.tangemGrayDark6)
                            + Text(symbolFormatted)
                            .foregroundColor(Color(name: "manage_tokens_gray_text"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .font(.system(size: 17, weight: .medium, design: .default))

                    VStack {
                        if isExpanded {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(Color(name: "manage_tokens_gray_text"))

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
                                        LegacyCoinItemView(model: model.items[index], arrowWidth: iconWidth).icon
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
                    ForEach(model.items) { LegacyCoinItemView(model: $0, arrowWidth: iconWidth) }
                }
            }
        }
        .padding(.vertical, 10)
        .animation(nil) // Disable animations on scroll reuse
    }

    private var chevronView: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 17, weight: .medium, design: .default))
            .rotationEffect(isExpanded ? Angle(degrees: 180) : .zero)
            .foregroundColor(Color(hex: "#CCCCCC")!)
            .padding(.vertical, 4)
    }
}

struct CurrencyView_Previews: PreviewProvider {
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
