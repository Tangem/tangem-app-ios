//
//  ExpressCoordinatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ExpressCoordinator

    init(coordinator: ExpressCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                ExpressView(viewModel: rootViewModel)
            }
            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .iOS16UIKitSheet(item: $coordinator.expressTokensListViewModel) {
                ExpressTokensListView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressApproveViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressApproveView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressFeeSelectorViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressFeeSelectorView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressProvidersSelectorViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressProvidersSelectorView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.swappingSuccessCoordinator) {
                SwappingSuccessCoordinatorView(coordinator: $0)
            }
    }
}

extension ExpressCoordinatorView {
    func expressNavigationView() -> some View {
        NavigationView {
            self
                .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButton(dismiss: { coordinator.closeSwappingView() })
                    }
                }
        }
    }
}
