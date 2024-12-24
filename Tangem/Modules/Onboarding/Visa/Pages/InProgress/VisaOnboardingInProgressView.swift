//
//  VisaOnboardingInProgressView.swift
//  Tangem
//
//  Created by Andrew Son on 19.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingInProgressView: View {
    @ObservedObject var viewModel: VisaOnboardingInProgressViewModel

    var body: some View {
        VStack(spacing: 26) {
            Assets.Onboarding.inProgress64.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
                .padding(.top, 126)

            VStack(spacing: 14) {
                Text(viewModel.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                Text(viewModel.description)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 54)

            Spacer()

            MainButton(
                title: Localization.warningButtonRefresh,
                isLoading: viewModel.isLoading,
                action: viewModel.refreshAction
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }
}
