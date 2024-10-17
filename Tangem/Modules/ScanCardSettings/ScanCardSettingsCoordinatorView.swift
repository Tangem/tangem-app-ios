//
//  ScanCardSettingsCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ScanCardSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ScanCardSettingsCoordinator

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            ScanCardSettingsView(viewModel: rootViewModel)
                .navigationLinks(links)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.cardSettingsCoordinator) {
                CardSettingsCoordinatorView(coordinator: $0)
            }
            .emptyNavigationLink()
    }
}
