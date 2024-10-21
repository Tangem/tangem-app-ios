//
//  MarketsTokenDetailsCoordinatorView.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsTokenDetailsCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                MarketsTokenDetailsView(viewModel: viewModel)
                    .navigationLinks(links)
            }

            sheets
        }
        .bindAlert($coordinator.error)
    }

    @ViewBuilder
    var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .iOS16UIKitSheet(item: $coordinator.expressCoordinator) {
                ExpressCoordinatorView(coordinator: $0)
            }
            .detentBottomSheet(
                item: $coordinator.tokenNetworkSelectorCoordinator,
                detents: [.large],
                settings: .init(background: Colors.Background.tertiary)
            ) {
                MarketsTokenNetworkSelectorCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .bottomSheet(
                item: $coordinator.warningBankCardViewModel,
                backgroundColor: Colors.Background.primary
            ) {
                WarningBankCardView(viewModel: $0)
                    .padding(.bottom, 10)
            }
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary, contentScrollsHorizontally: true)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.exchangesListViewModel) { viewModel in
                let container = NavigationBarHidingView(shouldWrapInNavigationView: false) {
                    MarketsTokenDetailsExchangesListView(viewModel: viewModel)
                }

                if #available(iOS 16, *) {
                    container
                } else {
                    container
                        .ignoresSafeArea(.container, edges: .vertical) // Without this on iOS 15 content won't ignore safe area and don't go below navbar
                }
            }
            .emptyNavigationLink()
    }
}
