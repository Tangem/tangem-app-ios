//
//  ActionButtonsBuyCoordinatorView.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import SwiftUI

struct ActionButtonsBuyCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsBuyCoordinator

    var body: some View {
        if let sendCoordinator = coordinator.sendCoordinator {
            SendCoordinatorView(coordinator: sendCoordinator)
        } else if let actionButtonsBuyViewModel = coordinator.actionButtonsBuyViewModel {
            NavigationView {
                ActionButtonsBuyView(viewModel: actionButtonsBuyViewModel)
                    .sheet(item: $coordinator.addToPortfolioBottomSheetInfo, content: { addToPortfolioSheet($0) })
            }
        }
    }

    private func addToPortfolioSheet(_ info: HotCryptoAddToPortfolioModel) -> some View {
        HotCryptoAddPortfolioBottomSheet(
            info: info,
            action: {
                coordinator.actionButtonsBuyViewModel?.handleViewAction(.addToPortfolio(info.token))
            }
        )
        .adaptivePresentationDetents()
        .background(Colors.Background.tertiary)
    }
}
