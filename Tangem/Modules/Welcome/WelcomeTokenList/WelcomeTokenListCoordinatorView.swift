//
//  WelcomeTokenListCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeTokenListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeTokenListCoordinator

    var body: some View {
        NavigationView {
            if let model = coordinator.tokenListViewModel {
                WelcomeTokenListView(viewModel: model)
                    .navigationLinks(links)
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .emptyNavigationLink()
    }
}
