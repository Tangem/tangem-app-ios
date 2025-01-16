//
//  HotCryptoAddPortfolioBottomSheet.swift
//  TangemApp
//
//  Created by GuitarKitty on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import SwiftUI

struct HotCryptoAddPortfolioBottomSheet: View {
    let info: HotCryptoAddToPortfolioModel
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Add token")
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .padding(.bottom, 8)

            Text("to \(info.walletName)")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 28)

            IconView(url: info.token.imageURL, size: .init(bothDimensions: 36))
                .padding(.bottom, 16)

            Text(info.token.name)
                .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
                .padding(.bottom, 16)

            Text("In \(Blockchain.allMainnetCases.first(where: { $0.networkId == info.token.networkId })?.displayName ?? "")")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 16)

            MainButton(title: "Add to portfolio", icon: .trailing(Assets.tangemIcon), action: action)
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 16)
    }
}
