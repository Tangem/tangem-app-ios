//
//  MainBottomSheetCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 04.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MainBottomSheetCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainBottomSheetCoordinator

    var body: some View {
        ZStack {
            sheets
        }
        .if(coordinator.isMainBottomSheetEnabled) { view in
            // Unfortunately, we can't just apply the `bottomScrollableSheet` modifier here conditionally only when
            // `coordinator.mainBottomSheetViewModel != nil` because this will break the root view's structural identity and
            // therefore all its state. Therefore `bottomScrollableSheet` view modifier is always applied,
            // but `header`/`content` views are created only when there is a non-nil `mainBottomSheetViewModel`
            view.bottomScrollableSheet(
                isHiddenWhenCollapsed: true,
                allowsHitTesting: coordinator.mainBottomSheetViewModel != nil,
                header: {
                    if let viewModel = coordinator.mainBottomSheetViewModel {
                        MainBottomSheetHeaderContainerView(viewModel: viewModel)
                    }
                },
                content: {
                    if let viewModel = coordinator.mainBottomSheetViewModel {
                        MainBottomSheetContentView(viewModel: viewModel)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.networkSelectorCoordinator) {
                ManageTokensNetworkSelectorCoordinatorView(coordinator: $0)
            }
    }
}
