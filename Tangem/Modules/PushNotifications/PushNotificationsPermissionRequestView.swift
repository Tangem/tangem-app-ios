//
//  PushNotificationsPermissionRequestView.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PushNotificationsPermissionRequestView: View {
    @ObservedObject private var viewModel: PushNotificationsPermissionRequestViewModel

    @Environment(\.colorScheme) private var colorScheme

    private let topInset: CGFloat
    private let buttonsAxis: Axis

    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer(height: 62.0 + topInset)

            Group {
                VStack(spacing: 0.0) {
                    Assets.notificationBell.image
                        .renderingMode(.template)
                        .foregroundColor(iconColor)

                    FixedSpacer(height: 28.0)

                    Text(Localization.userPushNotificationAgreementHeader)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                FixedSpacer(height: 44.0)

                VStack(spacing: 0.0) {
                    OnboardingFeatureDescriptionView(
                        icon: Assets.notificationBulletItemOne,
                        description: Localization.userPushNotificationAgreementArgumentOne
                    )

                    FixedSpacer(height: 28.0)

                    OnboardingFeatureDescriptionView(
                        icon: Assets.notificationBulletItemTwo,
                        description: Localization.userPushNotificationAgreementArgumentTwo
                    )
                }
                .layoutPriority(100) // Higher layout priority causes spacers to collapse if there is not enough vertical space
            }
            .padding(.horizontal, 22.0)

            // We have more vertical space when buttons are laid out horizontally,
            // so the minimal height for this spacer can be increased
            Spacer(minLength: buttonsAxis == .horizontal ? 44.0 : nil)

            buttonsContainer
                .layoutPriority(101) // Higher layout priority causes spacers to collapse if there is not enough vertical space
        }
    }

    @ViewBuilder
    private var buttonsContainer: some View {
        Group {
            switch buttonsAxis {
            case .horizontal:
                HStack(spacing: 10.0) { buttons }
            case .vertical:
                VStack(spacing: 8.0) { buttons }
            }
        }
        .padding(.bottom, 6.0)
        .padding(.horizontal, 16.0)
    }

    @ViewBuilder
    private var buttons: some View {
        MainButton(
            title: viewModel.allowButtonTitle,
            action: viewModel.didTapAllow
        )

        MainButton(
            title: viewModel.laterButtonTitle,
            style: .secondary,
            action: viewModel.didTapLater
        )
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
        viewModel: PushNotificationsPermissionRequestViewModel,
        topInset: CGFloat,
        buttonsAxis: Axis
    ) {
        self.viewModel = viewModel
        self.topInset = topInset
        self.buttonsAxis = buttonsAxis
    }
}

// MARK: - Previews

#Preview {
    let viewModel = PushNotificationsPermissionRequestViewModel(
        permissionManager: PushNotificationsPermissionManagerStub(),
        delegate: PushNotificationsPermissionRequestDelegateStub()
    )

    return VStack {
        PushNotificationsPermissionRequestView(viewModel: viewModel, topInset: 0.0, buttonsAxis: .vertical)

        Spacer()

        PushNotificationsPermissionRequestView(viewModel: viewModel, topInset: 0.0, buttonsAxis: .horizontal)
    }
}
