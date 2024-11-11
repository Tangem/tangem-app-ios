//
//  OnboardingPinView.swift
//  Tangem
//
//  Created by Andrew Son on 08.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingPinView: View {
    @ObservedObject var viewModel: OnboardingPinViewModel

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 10) {
                Text("Create PIN Code")
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                Text("Set up a 4-digit code.\nIt will be used for payments.")
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            OnboardingPinStackView(
                maxDigits: viewModel.pinCodeLength,
                pinText: $viewModel.pinCode
            )

            Spacer()

            MainButton(
                title: "Submit",
                isDisabled: !viewModel.isPinCodeValid,
                action: viewModel.submitPinCodeAction
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    OnboardingPinView(viewModel: .init(pinCodeSaver: { pinCode in
        print("Saved pin code: \(pinCode)")
    }))
}
