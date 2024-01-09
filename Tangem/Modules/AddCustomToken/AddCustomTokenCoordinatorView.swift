//
//  AddCustomTokenCoordinatorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddCustomTokenCoordinator

    init(coordinator: AddCustomTokenCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    AddCustomTokenView(viewModel: rootViewModel)
                        .navigationLinks(links)
                }

                sheets
            }
        }
        .accentColor(Colors.Text.primary1)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.networkSelectorModel) {
                AddCustomTokenNetworkSelectorView(viewModel: $0)
            }
            .navigation(item: $coordinator.derivationSelectorModel) {
                AddCustomTokenDerivationPathSelectorView(viewModel: $0)
            }
            .navigation(item: $coordinator.walletSelectorViewModel) {
                WalletSelectorView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
