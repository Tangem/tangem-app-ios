//
//  PromotionCoordinatorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct PromotionCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PromotionCoordinator

    init(coordinator: PromotionCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                PromotionView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
