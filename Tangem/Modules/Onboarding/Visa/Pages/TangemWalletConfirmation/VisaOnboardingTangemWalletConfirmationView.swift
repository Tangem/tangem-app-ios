//
//  VisaOnboardingTangemWalletConfirmationView.swift
//  Tangem
//
//  Created by Andrew Son on 04.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingTangemWalletConfirmationView: View {
    @ObservedObject var viewModel: VisaOnboardingTangemWalletConfirmationViewModel

    private let cardImageAspectRatio: CGFloat = 1.591
    private let imageToTextOffsetRatio: CGFloat = 0.169

    var body: some View {
        VStack(spacing: 0) {
            cardImage

            Spacer()

            VStack(spacing: 14) {
                Text("Prepare Tangem Wallet")
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)

                Text("Prepare the Tangem card and tap to approve")
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .padding(.horizontal, 22)
            }
            .padding(.bottom, 54)
            .padding(.horizontal, 32)

            Spacer()

            MainButton(
                title: "Approve",
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isLoading,
                action: viewModel.approveAction
            )
        }
        .padding(.top, 44)
        .padding(.bottom, 10)
    }

    private var cardImage: some View {
        ZStack {
            Colors.Button.primary
                .cornerRadiusContinuous(10)

            Assets.tangemIconBig.image
                .resizable()
                .frame(width: 38, height: 48)
        }
        .padding(.horizontal, 30)
        .aspectRatio(cardImageAspectRatio, contentMode: .fill)
    }
}
