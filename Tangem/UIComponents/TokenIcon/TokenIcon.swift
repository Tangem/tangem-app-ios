//
//  TokenIcon.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct TokenIcon: View {
    let name: String
    let imageURL: URL?
    let blockchainIconName: String?
    let isCustom: Bool

    var size = CGSize(width: 40, height: 40)
    private let networkIconSize = CGSize(width: 14, height: 14)
    private let networkIconBorderWidth: Double = 2
    private let customTokenIndicatorSize = CGSize(width: 8, height: 8)
    private let customTokenIndicatorBorderWidth: CGFloat = 2

    private var customTokenIndicatorBorderSize: CGSize {
        customTokenIndicatorSize + CGSize(width: 2 * customTokenIndicatorBorderWidth, height: 2 * customTokenIndicatorBorderWidth)
    }

    var body: some View {
        IconView(url: imageURL, size: size, forceKingfisher: true)
            .overlay(
                networkIcon.offset(x: 4, y: -4),
                alignment: .topTrailing
            )
            .overlay(
                customTokenIndicator
                    .frame(size: size, alignment: .bottomTrailing)
                    .offset(x: 1, y: 1)
            )
    }

    @ViewBuilder
    private var networkIcon: some View {
        if let iconName = blockchainIconName {
            NetworkIcon(
                imageName: iconName,
                isActive: true,
                isMainIndicatorVisible: false,
                size: networkIconSize
            )
            .background(
                Colors.Background.primary
                    .clipShape(Circle())
                    .frame(size: networkIconSize + CGSize(width: 2 * networkIconBorderWidth, height: 2 * networkIconBorderWidth))
            )
        }
    }

    @ViewBuilder
    private var customTokenIndicator: some View {
        if isCustom {
            Circle()
                .foregroundColor(Colors.Icon.informative)
                .frame(size: customTokenIndicatorSize)
                .background(
                    Circle()
                        .foregroundColor(Colors.Background.primary)
                        .frame(size: customTokenIndicatorBorderSize)
                )
        }
    }
}

struct TokenIcon_Preview: PreviewProvider {
    static let coins = [
        (id: "bitcoin", iconName: "bitcoin"),
        (id: "ethereum", iconName: nil),
        (id: "tether", iconName: "ethereum"),
        (id: "usd-coin", iconName: "ethereum"),
        (id: "matic-network", iconName: "ethereum"),
        (id: "binance-usd", iconName: "ethereum"),
        (id: "shiba-inu", iconName: "ethereum"),
        (id: "tron", iconName: nil),
        (id: "avalanche-2", iconName: nil),
        (id: "dai", iconName: "avalanche"),
        (id: "wrapped-bitcoin", iconName: "avalanche"),
        (id: "uniswap", iconName: "avalanche"),
    ]

    static var previews: some View {
        ScrollView {
            VStack {
                ForEach(coins, id: \.id) { coin in
                    TokenIcon(
                        name: coin.id, imageURL: TokenIconURLBuilder().iconURL(id: coin.id, size: .large),
                        blockchainIconName: coin.iconName,
                        isCustom: true
                    )
                }
            }
            .infinityFrame()
        }
    }
}
