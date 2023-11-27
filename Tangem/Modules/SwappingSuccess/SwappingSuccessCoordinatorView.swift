//
//  SwappingSuccessCoordinatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingSuccessCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SwappingSuccessCoordinator

    init(coordinator: SwappingSuccessCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.legacyRootViewModel {
                SwappingSuccessView(viewModel: rootViewModel)
            } else if let rootViewModel = coordinator.rootViewModel {
                ExpressSuccessSentView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.webViewContainerViewModel) {
                WebViewContainer(viewModel: $0)
            }
    }
}
