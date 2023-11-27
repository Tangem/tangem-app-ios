//
//  MainBottomSheetOverlayCoordinatorView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// - Note: Multiple separate root coordinator views are used in this module due to the architecture of the
/// scrollable bottom sheet UI component, which consists of three parts (views) - `header`, `content` and `overlay`.
struct MainBottomSheetOverlayCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainBottomSheetCoordinator

    var body: some View {
        if let viewModel = coordinator.overlayViewModel {
            MainBottomSheetOverlayView(viewModel: viewModel)
        }
    }
}
