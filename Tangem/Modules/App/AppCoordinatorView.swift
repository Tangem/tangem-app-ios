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

    @Environment(\.mainWindowSize) var mainWindowSize: CGSize
    @Environment(\.overlayContentContainer) private var overlayContentContainer
    @Namespace private var namespace

    var body: some View {
        NavigationView {
            content
                .navigationLinks(links)
        }
        .animation(.default, value: coordinator.viewState)
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
        .overlayContentContainer(item: $coordinator.marketsCoordinator) { coordinator in
            let viewHierarchySnapshotter = ViewHierarchySnapshottingContainerViewController()
            viewHierarchySnapshotter.shouldPropagateOverriddenUserInterfaceStyleToChildren = true
            let adapter = ViewHierarchySnapshottingWeakifyAdapter(adaptee: viewHierarchySnapshotter)
            let marketsCoordinatorView = MarketsCoordinatorView(coordinator: coordinator)
                .environment(\.mainWindowSize, mainWindowSize)
                .environment(\.viewHierarchySnapshotter, adapter)

            return UIAppearanceBoundaryContainerView(
                boundaryMarker: { viewHierarchySnapshotter },
                content: { marketsCoordinatorView }
            )
            // Ensures that this is a full-screen container and keyboard avoidance is disabled to mitigate IOS-7997
            .ignoresSafeArea(.all, edges: .vertical)
        }
        .bottomSheet(
            item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
            backgroundColor: Colors.Background.primary
        ) {
            InformationHiddenBalancesView(viewModel: $0)
        }
        .onChange(of: coordinator.isOverlayContentContainerShown) { isShown in
            overlayContentContainer.setOverlayHidden(!isShown)
        }
        .overlay {
            if coordinator.lockViewVisible {
                LockView()
                    .setNamespace(namespace)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .welcome(let welcomeCoordinator):
            WelcomeCoordinatorView(coordinator: welcomeCoordinator)
        case .uncompleteBackup(let uncompletedBackupCoordinator):
            UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
        case .auth(let authCoordinator):
            AuthCoordinatorView(coordinator: authCoordinator)
                .setNamespace(namespace)
        case .main(let mainCoordinator):
            MainCoordinatorView(coordinator: mainCoordinator)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }
}
