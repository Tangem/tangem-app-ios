//
//  WalletPromoBannerView.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletPromoBannerView: View {
    @ObservedObject var viewModel: WalletPromoBannerViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Assets.walletPromoImage.image

            Text(Localization.walletPromoBannerTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.constantWhite)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            Text(Localization.walletPromoBannerDescription)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            MainButton(
                title: Localization.walletPromoBannerButtonTitle,
                style: .primary,
                size: .notification,
                action: viewModel.didTapWalletPromo
            )
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .environment(\.colorScheme, .dark)
        .cornerRadiusContinuous(14)
        .onAppear(perform: viewModel.onAppear)
    }
}
