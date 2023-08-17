//
//  UserWalletStorageAgreementView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletStorageAgreementView: View {
    @ObservedObject private var viewModel: UserWalletStorageAgreementViewModel

    init(viewModel: UserWalletStorageAgreementViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                BiometryLogoImage.image.image

                FlexibleSpacer(maxHeight: 28)

                Text(Localization.saveUserWalletAgreementHeader(BiometricAuthorizationUtils.biometryType.name))
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                FlexibleSpacer(maxHeight: 28)
            }

            Spacer()

            VStack(spacing: 0) {
                FeatureDescriptionView(
                    icon: BiometryLogoImage.image,
                    title: Localization.saveUserWalletAgreementAccessTitle,
                    description: Localization.saveUserWalletAgreementAccessDescription
                )

                FlexibleSpacer(maxHeight: 28)

                FeatureDescriptionView(
                    icon: Assets.lock,
                    title: Localization.saveUserWalletAgreementCodeTitle,
                    description: Localization.saveUserWalletAgreementCodeDescription(BiometricAuthorizationUtils.biometryType.name)
                )
            }

            Spacer()

            VStack(spacing: 10) {
                MainButton(title: BiometricAuthorizationUtils.allowButtonTitle, action: viewModel.accept)

                MainButton(
                    title: Localization.saveUserWalletAgreementDontAllow,
                    style: .secondary,
                    action: viewModel.decline
                )

                Text(Localization.saveUserWalletAgreementNotice)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

private extension UserWalletStorageAgreementView {
    struct FlexibleSpacer: View {
        let maxHeight: CGFloat

        var body: some View {
            Spacer()
                .frame(maxHeight: maxHeight)
        }
    }

    struct FeatureDescriptionView: View {
        let icon: ImageType
        let title: String
        let description: String

        private let iconSize: Double = 42

        var body: some View {
            HStack(spacing: 16) {
                Colors.Background.secondary
                    .frame(width: iconSize, height: iconSize)
                    .cornerRadius(iconSize / 2)
                    .overlay(
                        icon.image
                            .resizable()
                            .foregroundColor(Colors.Text.primary1)
                            .padding(.all, 11)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                    Text(description)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
    }
}
