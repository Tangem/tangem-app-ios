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
            switch coordinator.viewState {
            case .welcome(let welcomeCoordinator):
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            case .uncompleteBackup(let uncompletedBackupCoordinator):
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            case .auth(let authCoordinator):
                AuthCoordinatorView(coordinator: authCoordinator)
                    .if(coordinator.mainBottomSheetCoordinator != nil) { view in
                        view.animation(nil) // Fixes weird animations on appear when the view has a bottom scrollable sheet
                    }
            case .main(let mainCoordinator):
                MainCoordinatorView(coordinator: mainCoordinator)
            case .none:
                EmptyView()
            }
        }
        .animation(.default, value: coordinator.viewState)
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
                    item: mainBottomSheetCoordinator,
                    header: MainBottomSheetHeaderCoordinatorView.init,
                    content: MainBottomSheetContentCoordinatorView.init,
                    overlay: MainBottomSheetOverlayCoordinatorView.init
                )
                .bottomScrollableSheetConfiguration(
                    isHiddenWhenCollapsed: true,
                    allowsHitTesting: coordinator.isMainBottomSheetShown
                )
                .onBottomScrollableSheetStateChange(
                    weakify(mainBottomSheetCoordinator, forFunction: MainBottomSheetCoordinator.onBottomScrollableSheetStateChange)
                )
        }
        .bottomSheet(
            item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
            backgroundColor: Colors.Background.primary
        ) {
            InformationHiddenBalancesView(viewModel: $0)
        }
    }
}
