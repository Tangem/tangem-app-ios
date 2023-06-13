//
//  SwappingCoordinatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SwappingCoordinator

    init(coordinator: SwappingCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                SwappingView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.swappingTokenListViewModel) {
                SwappingTokenListView(viewModel: $0)
            }

        if FeatureProvider.isAvailable(.abilityChooseApproveAmount) {
            NavHolder()
                .bottomSheet(item: $coordinator.swappingApproveViewModel) {
                    SwappingApproveView(viewModel: $0)
                }
        } else {
            NavHolder()
                .bottomSheet(item: $coordinator.swappingPermissionViewModel) {
                    SwappingPermissionView(viewModel: $0)
                }
        }

        NavHolder()
            .sheet(item: $coordinator.swappingSuccessCoordinator) {
                SwappingSuccessCoordinatorView(coordinator: $0)
            }
    }
}
