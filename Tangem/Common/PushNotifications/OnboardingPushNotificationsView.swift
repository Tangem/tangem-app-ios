//
//  OnboardingPushNotificationsView.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingPushNotificationsView: View {
    @ObservedObject var viewModel: OnboardingPushNotificationsViewModel

    var body: some View {
        VStack {
            Spacer()

            // TODO: https://tangem.atlassian.net/browse/IOS-6136
            Text("PUSH NOTIFICATIONS CONTENT")

            Spacer()

            buttons
        }
    }

    private var buttons: some View {
        VStack {
            MainButton(
                title: "Allow", // TODO: https://tangem.atlassian.net/browse/IOS-6136
                action: viewModel.didTapAllow
            )

            MainButton(
                title: Localization.commonLater,
                style: .secondary,
                action: viewModel.didTapLater
            )
        }
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    OnboardingPushNotificationsView(viewModel: .init(delegate: OnboardingPushNotificationsDelegateStub()))
}
