//
//  GenerateAddressesView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 12.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct GenerateAddressesView: View {
    let viewModel: GenerateAddressesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Colors.Icon.accent
                    .frame(size: CGSize(bothDimensions: 36))
                    .clipShape(Circle())
                    .opacity(0.12)
                    .overlay(Assets.blueCircleWarning.image)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.warningMissingDerivationTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text(Localization.warningMissingDerivationMessage(viewModel.numberOfNetworks))
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }

            MainButton(
                title: Localization.commonGenerateAddresses,
                subtitle: Localization.manageTokensNumberOfWalletsIos(viewModel.currentWalletNumber, viewModel.totalWalletNumber),
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                action: viewModel.didTapGenerate
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .padding(.bottom, UIApplication.safeAreaInsets.bottom)
        .background(Colors.Background.action.ignoresSafeArea())
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.12), radius: 32, x: 0, y: -5)
    }
}

struct GenerateAddressesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = GenerateAddressesViewModel(
            numberOfNetworks: 1,
            currentWalletNumber: 2,
            totalWalletNumber: 3,
            didTapGenerate: {}
        )

        return Colors.Background.primary.ignoresSafeArea()
            .overlay(GenerateAddressesView(viewModel: viewModel), alignment: .bottom)
    }
}
