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

    @StateObject private var sheetViewModelHolder = ManageTokensSheetViewModelHolder()

    var body: some View {
        NavigationView {
            if let welcomeCoordinator = coordinator.welcomeCoordinator {
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            } else if let uncompletedBackupCoordinator = coordinator.uncompletedBackupCoordinator {
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            } else if let authCoordinator = coordinator.authCoordinator {
                AuthCoordinatorView(coordinator: authCoordinator)
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
        .onPreferenceChange(ManageTokensSheetViewModelPreferenceKey.self) { newValue in
            // `DispatchQueue.main.async` used here to allow publishing changes during view update
            DispatchQueue.main.async {
                sheetViewModelHolder.viewModel = newValue?.value
            }
        }
        .bottomScrollableSheet(
            header: {
                // FIXME: Andrey Fedorov - Severe lags on page change
                if let viewModel = sheetViewModelHolder.viewModel {
                    _ManageTokensHeaderView(viewModel: viewModel)
                } else {
                    EmptyView()
                }
            },
            content: {
                // FIXME: Andrey Fedorov - Severe lags on page change
                if let viewModel = sheetViewModelHolder.viewModel {
                    _ManageTokensView(viewModel: viewModel)
                } else {
                    EmptyView()
                }
            }
        )
    }
}

// MARK: - Auxiliary types

private final class ManageTokensSheetViewModelHolder: ObservableObject {
    @Published var viewModel: ManageTokensSheetViewModel?
}
