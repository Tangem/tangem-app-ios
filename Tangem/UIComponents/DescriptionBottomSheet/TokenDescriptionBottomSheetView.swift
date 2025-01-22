//
//  TokenDescriptionBottomSheetView.swift
//  Tangem
//
//  Created by Alexander Skibin on 01.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import MarkdownUI
import TangemUIUtils

struct TokenDescriptionBottomSheetView: View {
    let info: DescriptionBottomSheetInfo
    var generatedWithAIAction: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismissSheetAction

    // No additional padding is needed on devices with a notch, native safe area works fine.
    private var bottomInset: CGFloat { UIDevice.current.hasHomeScreenIndicator ? 0.0 : 10.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DescriptionBottomSheetView(info: info)

            Button {
                generatedWithAIAction?()
            } label: {
                generatedWithAILabel
            }
            .padding(.horizontal, 16)
            .disabled(generatedWithAIAction == nil)
        }
        .padding(.bottom, bottomInset)
    }
}

// View components
private extension TokenDescriptionBottomSheetView {
    var generatedWithAILabel: some View {
        HStack(spacing: 12) {
            Assets.stars.image
                .foregroundStyle(Colors.Icon.accent)

            Text(Localization.informationGeneratedWithAi)
                .multilineTextAlignment(.leading)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .defaultRoundedBackground(with: Colors.Background.tertiary)
    }
}

#Preview {
    TokenDescriptionBottomSheetView(info: .init(
        title: "About Ethereum",
        description: "Ethereum network is a blockchain network.\n- Ethereum is an open-source platform for decentralized applications.\n- It aims to create a world computer for building applications in a decentralized manner.\n- Supports smart contracts allowing developers to program digital value.\n- Examples of dapps include tokens, NFTs, DeFi apps, lending protocols, and decentralized exchanges.\n- Transactions and smart contract executions require Gas fees, paid in Ether (ETH).\n- Gas measures the computational effort needed for operations, with fees fluctuating based on network demand.\n\n• Tether (USDT) is a stablecoin pegged to the U.S. dollar. \n • It offers stability in the volatile crypto market. \n• Issued by Tether Limited, governed by British Virgin Islands laws.\n• Used on exchanges like Bitfinex for trading cryptocurrencies.\n• Facilitates quick and cheap fiat movement in exchanges.\n• No transaction fees, but conversion fees apply on Tether.to.\n• Supports Ethereum network; ending support on EOS, Algorand, and others."
    ))
}
