//
//  HotCryptoView.swift
//  TangemApp
//
//  Created by GuitarKitty on 09.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotCryptoView: View {
    private let priceUtility = HotCryptoPriceUtility()

    let items: [HotCryptoToken]
    let action: (HotCryptoToken) -> Void

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if items.isNotEmpty {
            GroupedSection(
                items,
                content: {
                    tokenItem(item: $0)
                        .padding(.vertical, 16)
                },
                header: {
                    DefaultHeaderView(Localization.tokensListHotCryptoHeader)
                        .padding(.init(top: 14, leading: 0, bottom: 10, trailing: 0))
                }
            )
            .settings(\.backgroundColor, Colors.Background.action)
        }
    }

    private func tokenItem(item: HotCryptoToken) -> some View {
        HStack(spacing: 12) {
            IconView(url: item.imageURL, size: Constants.iconSize)

            infoView(item: item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: { action(item) })
    }

    private func infoView(item: HotCryptoToken) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 6) {
                Text(priceUtility.formatFiatPrice(item.currentPrice))
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                TokenPriceChangeView(state: priceUtility.convertToPriceChangeState(from: item.priceChangePercentage24h))
            }
        }
        .lineLimit(1)
    }
}

private enum Constants {
    static let iconSize = CGSize(width: 36, height: 36)
}
