//
//  VisaOnboardingAccessCodeSetupView.swift
//  Tangem
//
//  Created by Andrew Son on 18.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingAccessCodeSetupView: View {
    @ObservedObject var viewModel: VisaOnboardingAccessCodeSetupViewModel

    private let buttonIcon: MainButton.Icon = .trailing(Assets.tangemIcon)

    var body: some View {
        VStack(spacing: 24) {
            descriptionContent
                .padding(.horizontal, 24)

            inputContent

            Spacer()

            MainButton(
                title: viewModel.viewState.buttonTitle,
                icon: viewModel.viewState.isButtonWithLogo ? buttonIcon : nil,
                isLoading: viewModel.isButtonBusy,
                isDisabled: viewModel.isButtonDisabled,
                action: viewModel.mainButtonAction
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 10)
    }

    private var descriptionContent: some View {
        VStack(spacing: 10) {
            Text(viewModel.viewState.title)
                .multilineTextAlignment(.center)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(viewModel.viewState.description)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
        }
    }

    private var inputContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            CustomPasswordTextField(
                placeholder: Localization.detailsManageSecurityAccessCode,
                color: Colors.Text.primary1,
                password: $viewModel.accessCode,
                onCommit: {}
            )
            .frame(height: 48)
            .disabled(viewModel.isInputDisabled)

            Text(viewModel.errorMessage ?? " ")
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                .id("error_\(viewModel.errorMessage ?? " ")")
                .hidden(viewModel.errorMessage == nil)
        }
    }
}
