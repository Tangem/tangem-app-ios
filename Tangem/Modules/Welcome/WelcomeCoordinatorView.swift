//
//  WelcomeCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WelcomeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeCoordinator

    var body: some View {
        ZStack {
            if let welcomeModel = coordinator.welcomeViewModel {
                WelcomeView(viewModel: welcomeModel)
                    .navigationLinks(links)
            }

            sheets
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.mainCoordinator) {
                LegacyMainCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.shopCoordinator) {
                ShopCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.promotionCoordinator) {
                PromotionCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.tokenListCoordinator) {
                TokenListCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
