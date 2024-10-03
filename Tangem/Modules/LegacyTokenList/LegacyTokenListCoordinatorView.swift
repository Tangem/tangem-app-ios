//
//  LegacyTokenListCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct LegacyTokenListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: LegacyTokenListCoordinator

    var body: some View {
        NavigationView {
            if let model = coordinator.tokenListViewModel {
                LegacyTokenListView(viewModel: model)
                    .navigationLinks(links)
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addCustomTokenViewModel) {
                LegacyAddCustomTokenView(viewModel: $0)
            }
            .emptyNavigationLink()
    }
}
