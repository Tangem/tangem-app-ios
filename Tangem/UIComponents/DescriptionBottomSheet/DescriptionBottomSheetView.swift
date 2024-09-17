//
//  DescriptionBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import MarkdownUI

struct DescriptionBottomSheetInfo: Identifiable, Equatable {
    let id: UUID = .init()

    let title: String?
    let description: String
    var isGeneratedWithAI: Bool = false

    static func == (lhs: DescriptionBottomSheetInfo, rhs: DescriptionBottomSheetInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct DescriptionBottomSheetView: View {
    let info: DescriptionBottomSheetInfo

    @State private var containerHeight: CGFloat = 0

    var body: some View {
        content
            .padding(.horizontal, 16)
    }

    private var content: some View {
        VStack(spacing: 14) {
            if let title = info.title {
                Text(title)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .padding(.vertical, 12)
            }

            Markdown { info.description }
                .markdownSoftBreakMode(.lineBreak)
                .markdownTextStyle(\.text, textStyle: {
                    FontFamily(.system())
                    FontWeight(.regular)
                    FontSize(16)
                    ForegroundColor(Colors.Text.primary1)
                })
                .markdownBlockStyle(\.paragraph, body: { configuration in
                    configuration.label
                        .relativeLineSpacing(.em(0.2))
                })
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            if info.isGeneratedWithAI {
                generatedWithAILabel
            }
        }
        .padding(.bottom, 10)
    }

    private var generatedWithAILabel: some View {
        HStack(spacing: 12) {
            Assets.stars.image
                .foregroundStyle(Colors.Icon.accent)

            Text(Localization.informationGeneratedWithAi)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .defaultRoundedBackground(with: Colors.Background.tertiary)
    }
}

#Preview {
    DescriptionBottomSheetView(info: .init(
        title: "About Ethereum",
        description: "Ethereum network is a blockchain network.\n- Ethereum is an open-source platform for decentralized applications.\n- It aims to create a world computer for building applications in a decentralized manner.\n- Supports smart contracts allowing developers to program digital value.\n- Examples of dapps include tokens, NFTs, DeFi apps, lending protocols, and decentralized exchanges.\n- Transactions and smart contract executions require Gas fees, paid in Ether (ETH).\n- Gas measures the computational effort needed for operations, with fees fluctuating based on network demand.\n\n• Tether (USDT) is a stablecoin pegged to the U.S. dollar. \n • It offers stability in the volatile crypto market. \n• Issued by Tether Limited, governed by British Virgin Islands laws.\n• Used on exchanges like Bitfinex for trading cryptocurrencies.\n• Facilitates quick and cheap fiat movement in exchanges.\n• No transaction fees, but conversion fees apply on Tether.to.\n• Supports Ethereum network; ending support on EOS, Algorand, and others."
    ))
}
