//
//  AuthCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AuthCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AuthCoordinator

    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            content

            sheets
        }
        // modifiers order is changed intentionally (see OnboardingCoordinatorView, WelcomeCoordinatorView):
        // navigation bar animation looks redundant in case of regular authentication
        .animation(.default, value: coordinator.transitionAnimationValue)
        .navigationBarHidden(coordinator.isNavigationBarHidden)
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .auth(let authViewModel):
            AuthView(viewModel: authViewModel)
                .navigationLinks(links)
        case .main(let mainCoordinator):
            MainCoordinatorView(coordinator: mainCoordinator)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
