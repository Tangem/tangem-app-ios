//
//  VisaOnboardingActivationWalletSelectorView.swift
//  Tangem
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingActivationWalletSelectorView: View {
    @ObservedObject var viewModel: VisaOnboardingActivationWalletSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            NotificationView(input: viewModel.instructionNotificationInput)
                .padding(.horizontal, 16)

            walletList

            Spacer()

            MainButton(title: "Continue", action: viewModel.continueAction)
                .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var walletList: some View {
        VStack(spacing: 10) {
            Text("Choose wallet")
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            ForEach(VisaOnboardingActivationWalletSelectorItemView.Option.allCases) { option in
                VisaOnboardingActivationWalletSelectorItemView(
                    item: option,
                    selected: viewModel.selectedOption == option,
                    tapAction: {
                        viewModel.selectOption(option)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}
