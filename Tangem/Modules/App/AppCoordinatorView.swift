//
//  AppCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var sensitiveTextVisibilityViewModel = SensitiveTextVisibilityViewModel.shared

    var body: some View {
        NavigationView {
            if let welcomeCoordinator = coordinator.welcomeCoordinator {
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            } else if let uncompletedBackupCoordinator = coordinator.uncompletedBackupCoordinator {
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            } else if let authCoordinator = coordinator.authCoordinator {
                AuthCoordinatorView(coordinator: authCoordinator)
                    .if(coordinator.mainBottomSheetCoordinator != nil) { view in
                        view.animation(nil) // Fixes weird animations on appear when the view has a bottom scrollable sheet
                    }
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
        .modifier(ifLet: coordinator.mainBottomSheetCoordinator) { view, mainBottomSheetCoordinator in
            // Unfortunately, we can't just apply the `bottomScrollableSheet` modifier here conditionally when
            // `mainBottomSheetCoordinator.headerViewModel != nil` or `mainBottomSheetCoordinator.contentViewModel != nil`
            // because this will change the structural identity of `AppCoordinatorView` and therefore all its state.
            //
            // Therefore, the `bottomScrollableSheet` view modifier is always applied when the main bottom sheet
            // coordinator exists, but `header`/`content` views are created only when there is a non-nil
            // `mainBottomSheetCoordinator.headerViewModel` or `mainBottomSheetCoordinator.contentViewModel`
            view
                .bottomScrollableSheet(
                    header: { MainBottomSheetHeaderCoordinatorView(coordinator: mainBottomSheetCoordinator) },
                    content: { MainBottomSheetContentCoordinatorView(coordinator: mainBottomSheetCoordinator) },
                    overlay: { MainBottomSheetOverlayCoordinatorView(coordinator: mainBottomSheetCoordinator) }
                )
                .bottomScrollableSheetConfiguration(
                    isHiddenWhenCollapsed: true,
                    allowsHitTesting: coordinator.isMainBottomSheetShown
                )
                .onBottomScrollableSheetStateChange(mainBottomSheetCoordinator.onBottomScrollableSheetStateChange(_:))
        }
        .bottomSheet(
            item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
            settings: .init(backgroundColor: Colors.Background.primary)
        ) {
            InformationHiddenBalancesView(viewModel: $0)
        }
    }
}
