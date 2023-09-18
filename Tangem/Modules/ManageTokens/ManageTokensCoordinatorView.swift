//
//  ManageTokensCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ManageTokensCoordinator

    var body: some View {
        NavigationView {
            if let model = coordinator.manageTokensViewModel {
                ManageTokensView(viewModel: model)
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
