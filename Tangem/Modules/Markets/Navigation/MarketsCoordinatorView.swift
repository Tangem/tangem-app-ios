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
            if let model = coordinator.rootViewModel {
                MarketsView(viewModel: model)

                sheets
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .bottomSheet(
                item: $coordinator.marketsListOrderBottonSheetViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                MarketsListOrderBottonSheetView(viewModel: $0)
            }
            .sheet(item: $coordinator.tokenMarketsDetailsCoordinator) {
                TokenMarketsDetailsCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .emptyNavigationLink()
    }
}
