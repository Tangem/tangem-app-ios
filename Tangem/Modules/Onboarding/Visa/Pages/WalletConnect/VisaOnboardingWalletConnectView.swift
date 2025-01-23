//
//  VisaOnboardingWalletConnectView.swift
//  Tangem
//
//  Created by Andrew Son on 09/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingWalletConnectView: View {
    @ObservedObject var viewModel: VisaOnboardingWalletConnectViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Assets.Onboarding.tangemPayWc.image

            VStack(spacing: 12) {
                Text("Go to Website")
                    .multilineTextAlignment(.center)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text("You will be able to complete your connection\non the third-party web-site\nand back to the Tangem app")
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
            .padding(.horizontal, 36)

            Spacer()

            VStack(spacing: 10) {
                MainButton(title: "Open in Browser", action: viewModel.openBrowser)

                MainButton(title: "Share Link", style: .secondary, action: viewModel.openShareSheet)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }
}

#Preview {
    VisaOnboardingWalletConnectView(viewModel: .init())
}
