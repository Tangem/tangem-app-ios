//
//  AppSettingsCoordinatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppSettingsCoordinator

    init(coordinator: AppSettingsCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            AppSettingsView(viewModel: rootViewModel)
                .navigationLinks(links)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.currencySelectViewModel) {
                CurrencySelectView(viewModel: $0)
            }
    }
}
