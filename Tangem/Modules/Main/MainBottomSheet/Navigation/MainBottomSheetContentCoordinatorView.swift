//
//  MainBottomSheetContentCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 04.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// - Note: Two separate root coordinator views are used in this module due to the architecture of the
/// scrollable bottom sheet UI component, which consists of two parts (views) - `header` and `content`.
struct MainBottomSheetContentCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainBottomSheetCoordinator

    var body: some View {
        if let viewModel = coordinator.contentViewModel {
            ZStack {
                MainBottomSheetContentView(viewModel: viewModel)

                sheets
            }
        }
    }

    @ViewBuilder private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.networkSelectorCoordinator) {
                ManageTokensNetworkSelectorCoordinatorView(coordinator: $0)
            }
    }
}
