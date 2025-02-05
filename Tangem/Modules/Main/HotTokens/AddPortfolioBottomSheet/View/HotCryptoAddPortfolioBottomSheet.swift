//
//  HotCryptoAddPortfolioBottomSheet.swift
//  TangemApp
//
//  Created by GuitarKitty on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotCryptoAddToPortfolioBottomSheet: View {
    let info: HotCryptoAddToPortfolioModel
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.commonAddToken)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .padding(.bottom, 8)

            Text(Localization.hotCryptoAddTokenSubtitle(info.userWalletName))
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 28)

            IconView(url: info.token.imageURL, size: .init(bothDimensions: 36))
                .padding(.bottom, 16)

            Text(info.token.name)
                .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
                .padding(.bottom, 16)

            Text(info.tokenNetworkName)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 16)

            MainButton(title: Localization.commonAddToPortfolio, icon: .trailing(Assets.tangemIcon), action: action)
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 16)
    }
}
