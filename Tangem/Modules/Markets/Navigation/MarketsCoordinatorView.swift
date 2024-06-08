//
//  MarketsCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.manageTokensViewModel {
                MarketsView(viewModel: model)

                sheets
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .detentBottomSheet(
                item: $coordinator.networkSelectorViewModel,
                detents: [.medium, .large]
            ) { viewModel in
                NavigationView {
                    ManageTokensNetworkSelectorView(viewModel: viewModel)
                        .navigationLinks(links)
                }
                .navigationViewStyle(.stack)
            }
            .detentBottomSheet(
                item: $coordinator.addCustomTokenCoordinator,
                detents: [.large]
            ) { coordinator in
                AddCustomTokenCoordinatorView(coordinator: coordinator)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.walletSelectorViewModel) {
                WalletSelectorView(viewModel: $0)
            }
    }
}
