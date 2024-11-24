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
        .padding(.init(top: 32, leading: 16, bottom: 10, trailing: 16))
    }

    private var descriptionContent: some View {
        VStack(spacing: 10) {
            Text(viewModel.viewState.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(viewModel.viewState.description)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
        }
        .multilineTextAlignment(.center)
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
