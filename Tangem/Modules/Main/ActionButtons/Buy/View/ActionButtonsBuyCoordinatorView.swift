//
//  ActionButtonsBuyCoordinatorView.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsBuyView: View {
    @ObservedObject var coordinator: ActionButtonsBuyCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            content
                .navigationTitle(Localization.commonBuy)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButton(dismiss: dismiss.callAsFunction)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let tokenSelectorViewModel = coordinator.tokenSelectorViewModel {
            TokenSelectorView(
                viewModel: tokenSelectorViewModel,
                tokenCellContent: { token in
                    ActionButtonsTokenSelectItemView(model: token) {
                        coordinator.openBuy(for: token)
                    }
                },
                emptySearchContent: {
                    Text(tokenSelectorViewModel.strings.emptySearchMessage)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .animation(.default, value: tokenSelectorViewModel.searchText)
                }
            )
        }
    }
}
