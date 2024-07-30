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

    @Environment(\.colorScheme) private var colorScheme

    private let topInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            FixedSpacer(height: 62.0 + topInset)

            Group {
                VStack(spacing: 0.0) {
                    BiometryLogoImage.image.image
                        .renderingMode(.template)
                        .foregroundColor(iconColor)

                    FixedSpacer(height: 28.0)

                    Text(Localization.saveUserWalletAgreementHeader(BiometricAuthorizationUtils.biometryType.name))
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8.0)
                    .frame(maxHeight: 44.0)

                VStack(spacing: 0.0) {
                    OnboardingFeatureDescriptionView(
                        icon: BiometryLogoImage.image,
                        title: Localization.saveUserWalletAgreementAccessTitle,
                        description: Localization.saveUserWalletAgreementAccessDescription
                    )

                    FixedSpacer(height: 28.0)

                    OnboardingFeatureDescriptionView(
                        icon: Assets.lock,
                        title: Localization.saveUserWalletAgreementCodeTitle,
                        description: Localization.saveUserWalletAgreementCodeDescription(BiometricAuthorizationUtils.biometryType.name)
                    )
                }
                .layoutPriority(100) // Higher layout priority causes spacers to collapse if there is not enough vertical space
            }
            .padding(.horizontal, 22.0)

            Spacer(minLength: 8.0)

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
            .padding(.horizontal, 16.0)
            .layoutPriority(101) // Higher layout priority causes spacers to collapse if there is not enough vertical space
        }
        .padding(.bottom, 6)
    }

    private var iconColor: Color {
        switch colorScheme {
        case .light:
            return Colors.Icon.inactive
        case .dark:
            return Colors.Icon.primary1
        @unknown default:
            assertionFailure("Unknown color scheme '\(String(describing: colorScheme))' received")
            return Colors.Icon.inactive
        }
    }

    init(
        viewModel: UserWalletStorageAgreementViewModel,
        topInset: CGFloat
    ) {
        self.viewModel = viewModel
        self.topInset = topInset
    }
}
