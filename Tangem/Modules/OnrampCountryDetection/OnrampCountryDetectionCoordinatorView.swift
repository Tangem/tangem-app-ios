//
//  OnrampCountryDetectionCoordinatorView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 28.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampCountryDetectionCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: OnrampCountryDetectionCoordinator

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            OnrampCountryDetectionView(viewModel: rootViewModel)
                // We have to use `overlay` instead of ZStack to save the view size
                .overlay(content: { sheets })
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.onrampCountrySelectorViewModel) {
                OnrampCountrySelectorView(viewModel: $0)
            }
    }
}
