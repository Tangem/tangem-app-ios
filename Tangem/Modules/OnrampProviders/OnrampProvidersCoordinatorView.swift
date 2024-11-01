//
//  OnrampProvidersCoordinatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: OnrampProvidersCoordinator

    init(coordinator: OnrampProvidersCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    OnrampProvidersView(viewModel: rootViewModel)
                        .navigationLinks(links)
                }
            }
        }
        .tint(Colors.Text.primary1)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onrampPaymentMethodsViewModel) {
                OnrampPaymentMethodsView(viewModel: $0)
            }
            .emptyNavigationLink()
    }
}
