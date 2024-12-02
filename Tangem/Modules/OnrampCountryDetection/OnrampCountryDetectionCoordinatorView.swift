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
                // We have to save the `OnrampCountryDetectionView` size because it's a bottom sheet
                // If we will use `ZStack` the `CoordinatorView` will be expand on the whole screen
                // The `overlay` doesn't impact on `CoordinatorView` size
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
