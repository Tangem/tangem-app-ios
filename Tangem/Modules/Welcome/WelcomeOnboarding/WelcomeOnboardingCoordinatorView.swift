//
//  WelcomeOnboardingCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeOnboardingCoordinator

    init(coordinator: WelcomeOnboardingCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            WelcomeOnboardingView(viewModel: rootViewModel)
        }
    }
}
