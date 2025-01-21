//
//  WelcomeOnboardingView.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    @ObservedObject private var viewModel: WelcomeOnboardingViewModel

    init(viewModel: WelcomeOnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .background(.ultraThinMaterial)
            .transition(.opacity)
            .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        ZStack { // for transition animation
            switch viewModel.viewState {
            case .tos(let viewModel):
                WelcomeOnboardingTOSView(viewModel: viewModel)
                    .transition(.opacity.animation(.easeIn))
            case .pushNotifications(let viewModel):
                WelcomeOnboardingPushNotificationsView(viewModel: viewModel)
                    .transition(.opacity.animation(.easeIn))
            case .none:
                EmptyView()
            }
        }
    }
}

#Preview {
    WelcomeOnboardingView(
        viewModel: WelcomeOnboardingViewModel(
            steps: [.tos, .pushNotifications],
            pushNotificationsPermissionManager: PushNotificationsPermissionManagerStub(),
            coordinator: WelcomeOnboardingCoordinator()
        )
    )
}
