//
//  ActionButtonsSwapCoordinatorView.swift
//  TangemApp
//
//  Created by Viacheslav E. on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsSwapCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsSwapCoordinator

    var body: some View {
        NavigationView {
            ZStack {
                if let viewModel = coordinator.actionButtonsSwapViewModel {
                    ActionButtonsSwapView(viewModel: viewModel)
                        .opacity(coordinator.expressCoordinator == nil ? 1 : 0)
                        .animation(.easeInOut, value: coordinator.expressCoordinator == nil)
                }

                if let expressCoordinator = coordinator.expressCoordinator {
                    ExpressCoordinatorView(coordinator: expressCoordinator)
                        .transition(.opacity.animation(.easeInOut))
                }
            }
            .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: { coordinator.dismiss() })
                }
            }
        }
    }
}
